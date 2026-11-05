#!/bin/bash
# Double-click: makes the OM-3 colour editor update file from OM's official OM-3 firmware 1.1.
cd "$(dirname "$0")"
if ! command -v python3 >/dev/null 2>&1; then
  echo "Python 3 is needed. macOS will offer to install it (Command Line Tools); then double-click this again."
  xcode-select --install 2>/dev/null
  read -n 1 -s -r -p "Press any key to close."; exit 1
fi
python3 firmware/patch.py "$@"
echo
read -n 1 -s -r -p "Press any key to close."
