#!/usr/bin/env python3
"""Independent decoder for Olympus 'OE' firmware containers.

Written from the format description in docs/format/CONTAINERS.md:
  component = 32-byte header + encoded payload (len from header, multiple of 16)
              + 32-byte trailer (first 28 bytes repeat header; last word = checksum)
  decode: each 16-byte group, out[i] = in[PERM[i]] ^ 0xff
  check: sum of header + decoded payload + trailer as LE u32 words == 0 mod 2^32
Read-only: writes decoded payloads + a JSON report into a new output directory,
and verifies that re-encoding reproduces the input byte for byte.
"""
import argparse, hashlib, json, struct, sys
from pathlib import Path
import numpy as np

PERM = np.array([1, 3, 0, 2, 6, 4, 7, 5, 11, 10, 9, 8, 13, 14, 12, 15])
INV = np.argsort(PERM)


def decode(enc: bytes) -> bytes:
    a = np.frombuffer(enc, dtype=np.uint8).reshape(-1, 16)
    return (a[:, PERM] ^ 0xFF).tobytes()


def encode(dec: bytes) -> bytes:
    a = np.frombuffer(dec, dtype=np.uint8).reshape(-1, 16) ^ 0xFF
    return a[:, INV].tobytes()


def wordsum(b: bytes) -> int:
    return int(np.frombuffer(b, dtype='<u4').sum(dtype=np.uint64)) & 0xFFFFFFFF


def parse(data: bytes):
    comps, pos = [], 0
    while pos < len(data):
        hdr = data[pos:pos + 32]
        if len(hdr) < 32 or hdr[:2] != b'OE':
            raise SystemExit(f'bad header at {pos:#x}: {hdr[:4]!r}')
        addr, length = struct.unpack_from('<II', hdr, 8)
        build, = struct.unpack_from('<H', hdr, 16)
        kind, = struct.unpack_from('<H', hdr, 20)
        if length % 16 or pos + 64 + length > len(data):
            raise SystemExit(f'bad length {length:#x} at {pos:#x}')
        enc = data[pos + 32:pos + 32 + length]
        trl = data[pos + 32 + length:pos + 64 + length]
        if trl[:28] != hdr[:28]:
            raise SystemExit(f'header/trailer mismatch at {pos:#x}')
        dec = decode(enc)
        ok = (wordsum(hdr) + wordsum(dec) + wordsum(trl)) & 0xFFFFFFFF == 0
        comps.append(dict(offset=pos, model=hdr[2:4].hex(), addr=addr, length=length,
                          build=build, kind=kind, hdr_tail=hdr[28:32].hex(),
                          checksum_ok=ok, enc=enc, dec=dec, hdr=hdr, trl=trl))
        pos += 64 + length
    return comps


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('image')
    ap.add_argument('--out', required=True)
    ap.add_argument('--expect-sha256')
    args = ap.parse_args()
    data = Path(args.image).read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    if args.expect_sha256 and digest != args.expect_sha256:
        raise SystemExit(f'input hash mismatch: {digest}')
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=False)
    comps = parse(data)
    rebuilt = b''.join(c['hdr'] + encode(c['dec']) + c['trl'] for c in comps)
    report = dict(input_sha256=digest, input_bytes=len(data),
                  round_trip_identical=rebuilt == data, components=[])
    for i, c in enumerate(comps):
        name = f"{i:02d}_{c['kind']:04x}_{c['addr']:08x}.decoded.bin"
        (out / name).write_bytes(c['dec'])
        report['components'].append(dict(
            file=name, offset=hex(c['offset']), model=c['model'], addr=hex(c['addr']),
            length=c['length'], build=c['build'], kind=hex(c['kind']),
            hdr_tail=c['hdr_tail'], checksum_ok=c['checksum_ok'],
            decoded_sha256=hashlib.sha256(c['dec']).hexdigest()))
    (out / 'report.json').write_text(json.dumps(report, indent=2))
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
