"""The OM-3 film sims: our own looks, designed by hand from public descriptions of each film (maker data sheets,
reviews, sample photos) and tuned by eye on the Control Panel's sample photos. Each film is a short recipe of traits
that this script turns into ordinary OM-3 settings. No LUTs, presets or other people's looks are used.
usage: python3 scripts/films.py   (writes src/data/om3films.json)

Recipe keys (all integers; out-of-range sums are clamped to the camera's limits):
  sat           saturation for every colour            s_<f>  saturation of a colour family
  h_<f>         hue of a family: + turns it toward its clockwise neighbour on the OM-3 wheel:
                yellow → orange, orange → red, red → magenta, magenta → violet, blue → cyan, cyan → green, green → yellow
  l_<f>         lightness of a family
  families: y yellow, o orange (skin), r red (orange-red + red), m magenta (+ violet), b blue (+ blue-cyan), c cyan,
            g green (green-cyan + green + yellow-green); single sectors: Y O OR R M V B BC C GC G YG (e.g. s_YG)
  ab / gm       white balance shift: + amber / − blue, + green / − magenta
  con           the camera's Contrast (−2..2)
  hl sh mid     Highlights / Shadows / Midtones (+ brighter)      blk wht   Blacks (+ = lifted, faded) / Whites (− = dimmer)
No grain, Glow / Clarity or Art Effects: those stay the user's choice."""
import json, os

SECTORS = ['Y', 'O', 'OR', 'R', 'M', 'V', 'B', 'BC', 'C', 'GC', 'G', 'YG']
FAM = {'y': ['Y'], 'o': ['O'], 'r': ['OR', 'R'], 'm': ['M', 'V'], 'b': ['B', 'BC'], 'c': ['C'], 'g': ['GC', 'G', 'YG']}
LIM = {'hue': 5, 'light': 5, 'sat': 5, 'hl': 7, 'sh': 7, 'mid': 7, 'blk': 5, 'wht': 5, 'con': 2, 'ab': 5, 'gm': 5}

def settings(r):
    out = {'hue': [0] * 12, 'light': [0] * 12, 'sat': [r.get('sat', 0)] * 12}
    for k, v in r.items():
        if k[:2] in ('h_', 'l_', 's_'):
            arr = {'h_': 'hue', 'l_': 'light', 's_': 'sat'}[k[:2]]; f = k[2:]
            for s in FAM.get(f, [f]): out[arr][SECTORS.index(s)] += v
        else: assert k in LIM or k == 'sat', k
    for a in ('hue', 'light', 'sat'): out[a] = [max(-LIM[a], min(LIM[a], v)) for v in out[a]]
    c = lambda k: max(-LIM[k], min(LIM[k], r.get(k, 0)))
    out['tone'] = {'highlights': c('hl'), 'shadows': c('sh'), 'midtones': c('mid'), 'blacks': c('blk'), 'whites': c('wht')}
    out['contrast'] = c('con')
    out['wb'] = {'a_b': c('ab'), 'g_m': c('gm')} if r.get('ab') or r.get('gm') else None
    return out

# name (camera, ≤ 15 characters), group, film, description, recipe
FILMS = [
 # --- Fujifilm film simulations ---
 ('Fuji Provia', 'fuji', 'Fujifilm Provia / Standard', "Fujifilm's standard rendering, after Provia slide film: true-to-life colour and moderate contrast for almost anything.",
  dict(s_b=1, s_g=1, s_r=1)),
 ('Fuji Velvia', 'fuji', 'Fujifilm Velvia / Vivid', "Fujifilm's vivid mode, after Velvia: saturated greens and blues and strong contrast, made for landscapes.",
  dict(sat=2, s_g=2, s_b=2, s_m=1, s_o=-1, h_b=-1, con=2, sh=-2)),
 ('Fuji Astia', 'fuji', 'Fujifilm Astia / Soft', "Fujifilm's soft mode, after Astia slide film: gentle contrast and flattering skin with clean, bright colour.",
  dict(s_o=-1, s_b=1, l_o=1, con=-1, hl=-1, sh=1)),
 ('Classic Chrome', 'fuji', 'Fujifilm Classic Chrome', "Fujifilm's documentary look, inspired by mid-century magazine slides: muted colours, deep shadows and calm, cyan-leaning skies.",
  dict(sat=-2, s_r=-1, s_b=-1, h_b=1, s_g=-1, h_g=1, l_g=-1, l_r=-1, con=1, sh=-2, hl=-1)),
 ('Classic Neg', 'fuji', 'Fujifilm Classic Negative', "Fujifilm's look after Superia snapshots: hard contrast, muted colour, teal skies and greens, reds leaning magenta.",
  dict(sat=-1, s_y=-1, h_b=1, h_g=-1, h_r=1, s_g=-1, ab=-1, con=2, sh=-2, hl=-1)),
 ('Pro Neg Hi', 'fuji', 'Fujifilm Pro Neg. Hi', "Fujifilm's portrait negative look with a bit more punch: natural skin tones and moderate contrast.",
  dict(sat=-1, con=1, hl=-1)),
 ('Pro Neg Std', 'fuji', 'Fujifilm Pro Neg. Std', "Fujifilm's softest portrait look, after studio colour negative: low contrast, muted colour and smooth skin.",
  dict(sat=-2, s_o=1, con=-1, hl=-1, sh=1)),
 ('Eterna', 'fuji', 'Fujifilm Eterna / Cinema', "Fujifilm's cinema look, after Eterna motion-picture film: very low saturation, soft contrast and open shadows.",
  dict(sat=-3, s_o=1, h_b=1, h_g=-1, con=-2, sh=2, hl=-2, blk=1)),
 ('Reala Ace', 'fuji', 'Fujifilm Reala Ace', "Fujifilm's faithful negative look, after Superia Reala: natural, accurate colour with crisp contrast.",
  dict(s_g=1, s_b=1, con=1, sh=-1)),
 ('Nostalgic Neg', 'fuji', 'Fujifilm Nostalgic Neg.', "Fujifilm's 1970s-print look: amber warmth, rich skin in the shadows and gentle, soft contrast.",
  dict(ab=2, s_y=1, s_o=1, h_y=1, s_b=-1, h_b=1, con=-1, hl=-1, sh=1, blk=1)),
 # --- slide (reversal) film ---
 ('Velvia 50', 'slide', 'Fujichrome Velvia 50', "Fujichrome Velvia 50: the legendary landscape slide film, intense saturation, deep blues, lush greens and a hint of magenta.",
  dict(sat=3, s_g=1, s_b=1, s_m=1, s_o=-2, h_r=1, h_b=-1, gm=-1, con=2, sh=-3, blk=-1)),
 ('Velvia 100', 'slide', 'Fujichrome Velvia 100', "Fujichrome Velvia 100: very saturated slide film with strong reds and greens, a little calmer and warmer than Velvia 50.",
  dict(sat=3, s_o=-2, s_b=1, ab=1, con=2, sh=-2)),
 ('Provia 100F', 'slide', 'Fujichrome Provia 100F', "Fujichrome Provia 100F: the finest-grained Provia, accurate colour, clean blue skies and crisp, natural contrast.",
  dict(sat=1, s_b=1, s_o=-1, ab=-1, con=1, sh=-1)),
 ('Provia 400X', 'slide', 'Fujichrome Provia 400X', "Fujichrome Provia 400X: the last fast Provia, rich but natural colour with good highlight detail.",
  dict(sat=1, s_b=1, s_g=1, s_o=-1, con=1, sh=-2, hl=-1)),
 ('Astia 100F', 'slide', 'Fujichrome Astia 100F', "Fujichrome Astia 100F: Fuji's soft slide film for people, gentle contrast with accurate, delicate colour.",
  dict(s_o=-1, l_o=1, s_b=1, hl=-1)),
 ('Sensia 100', 'slide', 'Fujichrome Sensia 100', "Fujichrome Sensia 100: Fuji's consumer slide film, close to Provia with slightly brighter, warmer colour.",
  dict(sat=2, s_o=-1, ab=1, con=1, sh=-1)),
 ('Ektachrome E100', 'slide', 'Kodak Ektachrome E100', "Kodak Ektachrome E100: clean, neutral slide colour with crisp contrast and deep, clear blue skies.",
  dict(sat=1, s_b=2, h_b=-1, s_o=-1, ab=-1, con=1, sh=-1)),
 ('Ektachrome VS', 'slide', 'Kodak Ektachrome 100VS', "Kodak Ektachrome 100VS: Ektachrome's Very Saturated version, warm, punchy colour and strong contrast.",
  dict(sat=3, s_r=1, s_b=1, s_o=-1, ab=1, con=2, sh=-2)),
 ('EliteChrome 200', 'slide', 'Kodak Elite Chrome 200', "Kodak Elite Chrome 200: consumer slide film with bright, cheerful colour and a slightly cool cast.",
  dict(sat=2, s_b=1, s_o=-1, ab=-1, con=1, sh=-1)),
 ('Kodachrome 25', 'slide', 'Kodak Kodachrome 25', "Kodak Kodachrome 25: rich, archival slide colour with deep reds, strong blues, restrained greens and fine detail.",
  dict(sat=1, s_r=2, l_r=-1, s_y=1, s_g=-2, h_g=1, s_b=1, h_b=-1, l_b=-1, ab=1, con=1, sh=-2)),
 ('Kodachrome 64', 'slide', 'Kodak Kodachrome 64', "Kodak Kodachrome 64: the classic magazine slide film, warm reds and golden yellows, punchy blues and dense shadows.",
  dict(sat=1, s_r=3, l_r=-1, s_y=2, h_y=1, s_g=-1, h_g=1, s_b=2, l_b=-1, h_b=-1, ab=1, con=2, sh=-3)),
 ('Kodachrome 200', 'slide', 'Kodak Kodachrome 200', "Kodak Kodachrome 200: the fast Kodachrome, warmer and grittier, with Kodachrome's distinctive reds.",
  dict(sat=1, s_r=2, s_y=1, s_g=-1, ab=2, con=1, sh=-2)),
 ('Agfa Precisa', 'slide', 'Agfa CT Precisa 100', "Agfa CT Precisa 100: slide film with vivid, slightly cool colour, strong blues and greens and crisp contrast.",
  dict(sat=1, s_b=2, s_c=2, s_g=1, s_o=-1, ab=-1, con=1, sh=-1)),
 ('Polachrome', 'slide', 'Polaroid Polachrome', "Polaroid Polachrome: instant 35 mm slide film, dense and contrasty with low, earthy saturation.",
  dict(sat=-3, ab=2, gm=-1, con=2, sh=-2, wht=-1)),
 # --- colour negative ---
 ('Portra 160', 'neg', 'Kodak Portra 160', "Kodak Portra 160: the portrait standard, very natural skin, low contrast and smooth, gentle colour.",
  dict(sat=-1, s_g=-1, h_g=1, s_b=-1, con=-1, hl=-1, sh=1)),
 ('Portra 400', 'neg', 'Kodak Portra 400', "Kodak Portra 400: the most loved colour negative, warm, natural skin, soft greens and huge latitude.",
  dict(sat=-1, ab=1, h_o=-1, s_g=-1, h_g=1, s_b=-1, h_b=1, con=-1, hl=-1, sh=1)),
 ('Portra 800', 'neg', 'Kodak Portra 800', "Kodak Portra 800: fast Portra for low light, warmer and a little richer, with a touch more contrast.",
  dict(ab=2, h_o=-1, s_g=-1, h_g=1, s_b=-1, h_b=1, hl=-1)),
 ('Ektar 100', 'neg', 'Kodak Ektar 100', "Kodak Ektar 100: the finest-grained colour negative, with saturated colour, bold reds and strong, clean blues.",
  dict(sat=2, s_r=1, s_b=1, h_b=-1, s_o=-1, h_o=1, con=1, sh=-1)),
 ('Gold 200', 'neg', 'Kodak Gold 200', "Kodak Gold 200: the classic consumer film, warm and golden with rich yellows, friendly skin and yellowish greens.",
  dict(sat=1, ab=2, s_y=2, h_y=1, h_g=1, s_b=-1, con=1, sh=-1)),
 ('ColorPlus 200', 'neg', 'Kodak ColorPlus 200', "Kodak ColorPlus 200: the budget Kodak classic, warm and yellow-golden, softer than Gold, with a nostalgic snapshot feel.",
  dict(ab=2, s_y=2, h_y=1, s_g=-1, h_g=1, s_b=-1, hl=-1, blk=1)),
 ('Ultramax 400', 'neg', 'Kodak UltraMax 400', "Kodak UltraMax 400: Kodak's affordable all-rounder, warm, saturated and punchy with good skin tones.",
  dict(sat=2, ab=1, s_r=1, s_y=1, s_o=-1, h_g=1, con=1, sh=-1)),
 ('Pro Image 100', 'neg', 'Kodak Pro Image 100', "Kodak Pro Image 100: Kodak's portrait film for hot, bright places, warm and natural with moderate saturation.",
  dict(sat=1, ab=1, s_o=-1, s_g=1, con=1)),
 ('Kodacolor 100', 'neg', 'Kodak Kodacolor 100', "Kodak Kodacolor 100: Kodak's new fine-grained everyday film, the classic warm palette with yellow-leaning oranges and deep blues and greens.",
  dict(sat=1, ab=1, h_o=-1, l_o=1, s_b=1, s_g=1, con=1, sh=-1)),
 ('Superia 200', 'neg', 'Fujicolor Superia 200', "Fujicolor Superia 200: everyday consumer negative with Fuji's crisp greens, cyan skies and slightly cool tones.",
  dict(sat=1, gm=1, ab=-1, h_g=-1, s_g=1, h_b=1, con=1, sh=-1)),
 ('Superia 400', 'neg', 'Fujicolor Superia X-Tra 400', "Fujicolor Superia X-Tra 400: the classic everyday Fuji film, green-leaning colour, magenta-ish reds and snappy contrast.",
  dict(sat=1, gm=1, ab=-1, s_g=2, h_g=-1, h_b=1, h_r=1, con=1, sh=-1)),
 ('Superia 800', 'neg', 'Fujicolor Superia 800', "Fujicolor Superia 800: fast consumer negative with saturated colour, a green cast and slightly open shadows.",
  dict(gm=1, ab=-1, s_g=1, h_g=-1, con=1, blk=1)),
 ('Superia 1600', 'neg', 'Fujicolor Superia 1600', "Fujicolor Superia 1600: Fuji's fastest consumer negative, cool and green-tinged night-time colour with lifted blacks.",
  dict(sat=-1, gm=2, ab=-2, h_g=-1, sh=1, blk=1)),
 ('Superia Reala', 'neg', 'Fujicolor Superia Reala 100', "Fujicolor Superia Reala 100: fine-grained negative known for accurate, natural colour and good skin.",
  dict(sat=1, s_g=1, s_b=1, s_o=-1, con=1)),
 ('Fuji C200', 'neg', 'Fujicolor C200', "Fujicolor C200: Fuji's everyday film, with cool greens and blues, slightly muted reds and a clear, airy look.",
  dict(ab=-1, gm=1, s_r=-1, s_g=1, h_g=-1, s_b=1, h_b=1, mid=1)),
 ('Fujifilm 200', 'neg', 'Fujifilm 200', "Fujifilm 200: Fuji's current consumer film, close to Kodak Gold but softer, slightly warm with gentle colour.",
  dict(ab=1, s_y=1, h_y=1, h_g=1, hl=-1, sh=1)),
 ('Fuji 160C', 'neg', 'Fujicolor Pro 160C', "Fujicolor Pro 160C: a contrasty professional negative with richer colour than Fuji's portrait films.",
  dict(sat=1, s_g=1, s_b=1, s_o=-1, con=1, sh=-1)),
 ('Fuji 400H', 'neg', 'Fujicolor Pro 400H', "Fujicolor Pro 400H: the pastel wedding favourite, soft colour, airy highlights, cool skin and cyan-green tones.",
  dict(sat=-1, ab=-1, gm=1, h_g=-1, h_b=1, s_o=-1, l_o=1, mid=1, con=-1, sh=1)),
 ('Fuji 800Z', 'neg', 'Fujicolor Pro 800Z', "Fujicolor Pro 800Z: fast portrait negative with flattering skin and natural, slightly cool colour in low light.",
  dict(h_g=-1, s_o=-1, ab=-1, sh=1)),
 ('Agfa Vista 200', 'neg', 'Agfa Vista 200', "Agfa Vista 200: an inexpensive consumer negative with punchy reds, cool greens and a nostalgic feel.",
  dict(sat=2, s_r=2, s_o=-1, h_g=-1, ab=-1, con=1, sh=-1)),
 ('Agfa Ultra 100', 'neg', 'Agfa Ultra Color 100', "Agfa Ultra Color 100: one of the most saturated colour negatives ever made, bold and vivid.",
  dict(sat=4, s_o=-2, con=1, sh=-1)),
 ('Lomo Color 400', 'neg', 'Lomography Color Negative 400', "Lomography Color Negative 400: punchy, warm everyday film with saturated colour and a fun, lo-fi feel.",
  dict(sat=3, s_o=-1, s_r=1, s_y=1, ab=1, con=2, sh=-2)),
 ('LomoChrome 92', 'neg', "LomoChrome Color '92", "LomoChrome Color '92: Lomography's 90s-nostalgia film, faded and vintage with muted colour, strong blues and lifted shadows.",
  dict(sat=-2, s_b=2, h_b=-1, s_g=-1, h_g=1, con=-1, blk=2, wht=-1, sh=1)),
 ('Phoenix 200', 'neg', 'Harman Phoenix 200', "Harman Phoenix 200: the new from-scratch British colour film; high contrast, strong warm reds and an experimental, vintage feel.",
  dict(sat=1, s_r=3, s_o=1, s_g=-1, s_b=-1, h_b=1, ab=2, con=2, sh=-2, hl=1)),
 ('CineStill 50D', 'neg', 'CineStill 50D', "CineStill 50D: fine-grained daylight cinema film with clean, cool-leaning colour and smooth highlights.",
  dict(sat=1, ab=-1, s_o=-1, s_b=1, con=1, hl=-1, sh=-1)),
 ('CineStill 400D', 'neg', 'CineStill 400D', "CineStill 400D: daylight cinema film for stills, punchy pastel colour, rich warm skin and a slight green lean in the shadows.",
  dict(ab=1, gm=1, s_o=1, h_b=1, con=1, hl=-1)),
 ('CineStill 800T', 'neg', 'CineStill 800T', "CineStill 800T: tungsten-balanced cinema film made for night and city lights; cool, teal-leaning colour with warm practical lights.",
  dict(ab=-3, s_r=1, s_o=1, h_b=1, h_g=-1, con=1, sh=-1, hl=-1)),
 ('Vision3 250D', 'neg', 'Kodak Vision3 250D', "Kodak Vision3 250D: modern daylight motion-picture negative, neutral and very soft, with open shadows and gentle colour.",
  dict(sat=-2, con=-2, sh=2, hl=-2, blk=1)),
 ('Candido 800', 'neg', 'Candido 800', "Candido 800: cinema film re-spooled for stills, cool and soft with muted, slightly teal colour for night and mixed light.",
  dict(sat=-1, ab=-1, h_b=1, h_g=-1, con=-1, sh=1)),
 # --- instant ---
 ('FP-100C', 'instant', 'Fujifilm FP-100C', "Fujifilm FP-100C peel-apart instant film: soft contrast, cool blue-greens and creamy, dreamy colour.",
  dict(sat=1, ab=-1, s_g=1, h_g=-1, h_b=1, hl=-1, blk=1)),
 ('Polaroid 600', 'instant', 'Polaroid 600 colour film', "Polaroid 600 colour film: warm, low-contrast instant colour with creamy highlights and soft, faded blacks.",
  dict(sat=-1, ab=1, h_g=1, s_b=-1, con=-1, blk=2, wht=-2, sh=1)),
 ('Polaroid SX-70', 'instant', 'Polaroid SX-70 / Time Zero', "Polaroid SX-70 (Time Zero): the dreamy vintage instant look, warm and faded with muted greens and blues.",
  dict(sat=-1, ab=2, gm=-1, s_b=-2, h_b=2, s_g=-2, con=-1, blk=3, wht=-2)),
 ('Instax Mini', 'instant', 'Fujifilm Instax Mini', "Fujifilm Instax Mini: bright, punchy credit-card instant prints with clean, slightly cool colour.",
  dict(sat=1, ab=-1, s_b=1, mid=1, con=1)),
 # --- cinema print ---
 ('Kodak 2383', 'print', 'Kodak Vision 2383', "Kodak Vision 2383: the standard cinema print film, the classic movie look with deep blacks, teal shadows and warm skin.",
  dict(sat=1, s_o=1, h_b=1, h_g=-1, s_g=-1, con=2, sh=-2, blk=-1)),
 ('Kodak 2393', 'print', 'Kodak Vision Premier 2393', "Kodak Vision Premier 2393: premium cinema print film, deep blacks and rich but more neutral colour.",
  dict(sat=1, h_b=1, con=2, sh=-2, blk=-1)),
 ('Fuji 3513', 'print', 'Fujicolor Positive 3513DI', "Fujicolor Positive 3513DI: Fuji's cinema print film, softer and cooler than Kodak's, with a green-leaning palette.",
  dict(gm=1, ab=-1, h_g=-1, con=1, sh=-1)),
]

# Old film sim names (earlier versions of the list) → the film that replaces them, so looks added before keep their film.
ALIASES = {
 'Astia 100': 'Astia 100F', 'Provia 100': 'Provia 100F', 'Provia 400F': 'Provia 400X', 'EliteChrome 400': 'EliteChrome 200',
 'Elite ExtraCol': 'Ektachrome VS', 'Superia HG 1600': 'Superia 1600', 'Superia X-Tra': 'Superia 800', 'Superia 100': 'Superia 200',
 'Elite Color 200': 'Gold 200', 'Elite Color 400': 'Ultramax 400', 'Portra 800 HC': 'Portra 800', 'Portra 160 NC': 'Portra 160',
 'Portra 160 VC': 'Portra 160', 'Portra 400 NC': 'Portra 400', 'Portra 400 UC': 'Portra 400', 'Portra 400 VC': 'Portra 400',
 'FP-100C Cool': 'FP-100C', 'Polaroid 690': 'Polaroid 600', 'Pola 690 Warm': 'Polaroid 600', 'Fuji 3510': 'Fuji 3513',
 'Ektachrome FiF': 'Ektachrome E100', 'Ektar 100 FiF': 'Ektar 100', 'Ektar 100 PV': 'Ektar 100', 'Kodak Gold 200': 'Gold 200',
 'Kodak Gold PV': 'Gold 200', 'ColorPlus PV': 'ColorPlus 200', 'Ultramax PV': 'Ultramax 400', 'CineStill50D PV': 'CineStill 50D',
 'Phoenix 200 PV': 'Phoenix 200', 'Portra 160 FiF': 'Portra 160', 'Portra 160 PV': 'Portra 160', 'Portra 400 FiF': 'Portra 400',
 'Portra 400 PV': 'Portra 400', 'Portra 800 FiF': 'Portra 800', 'Provia 100F FiF': 'Provia 100F', 'Superia 400 FiF': 'Superia 400',
 'Kodak Dispo': 'Ultramax 400',
}

out = []
for name, grp, film, desc, recipe in FILMS:
    assert len(name) <= 15 and name.isascii() and name == name.strip(), name
    out.append({'name': name, 'group': grp, 'film': film, 'desc': desc, **settings(recipe)})
names = [f['name'] for f in out]
assert len(set(names)) == len(names), 'duplicate names'
assert all(v in names and k not in names for k, v in ALIASES.items())
json.dump({'note': 'Our own film looks (webapp/scripts/films.py); edit the recipes there, not this file.', 'films': out, 'aliases': ALIASES},
          open(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'src', 'data', 'om3films.json'), 'w'), separators=(',', ':'))
print(len(out), 'films')
