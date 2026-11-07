"""fit-luts.ts output -> src/data/om3films.json: the fitted settings with camera names (15 characters), groups and
sources. Fits worse than ΔE 8 are left out.
usage: python3 scripts/mkfilms.py FIT.json [FIT.json ...] src/data/om3films.json
  ids: <group>/<lut> for the G'MIC LUTs (lut-prep.py), fif/<film>/<lut> for the Film is Fun LUTs (lut-prep.py on
  their rec709 folders), parvec/<preset> for the PARVEC Lightroom presets (lr-prep.py)."""
import json, sys
NAMES = {
 'fujixtransiii/fuji_xtrans_iii_classic_chrome': ('Classic Chrome', 'fuji', 'Fujifilm Classic Chrome'),
 'fujixtransiii/fuji_xtrans_iii_provia': ('Fuji Provia', 'fuji', 'Fujifilm Provia / Standard'),
 'fujixtransiii/fuji_xtrans_iii_velvia': ('Fuji Velvia', 'fuji', 'Fujifilm Velvia / Vivid'),
 'fujixtransiii/fuji_xtrans_iii_astia': ('Fuji Astia', 'fuji', 'Fujifilm Astia / Soft'),
 'fujixtransiii/fuji_xtrans_iii_pro_neg_hi': ('Pro Neg Hi', 'fuji', 'Fujifilm Pro Neg. Hi'),
 'fujixtransiii/fuji_xtrans_iii_pro_neg_std': ('Pro Neg Std', 'fuji', 'Fujifilm Pro Neg. Std'),
 'colorslide/agfa_precisa_100': ('Agfa Precisa', 'slide', 'Agfa CT Precisa 100'),
 'colorslide/fuji_astia_100_generic': ('Astia 100', 'slide', 'Fujichrome Astia 100'),
 'colorslide/fuji_astia_100f': ('Astia 100F', 'slide', 'Fujichrome Astia 100F'),
 'colorslide/fuji_provia_100_generic': ('Provia 100', 'slide', 'Fujichrome Provia 100'),
 'colorslide/fuji_provia_100f': ('Provia 100F', 'slide', 'Fujichrome Provia 100F'),
 'colorslide/fuji_provia_400f': ('Provia 400F', 'slide', 'Fujichrome Provia 400F'),
 'colorslide/fuji_provia_400x': ('Provia 400X', 'slide', 'Fujichrome Provia 400X'),
 'colorslide/fuji_sensia_100': ('Sensia 100', 'slide', 'Fujichrome Sensia 100'),
 'colorslide/fuji_superia_200_xpro': ('Superia XPro', 'slide', 'Fuji Superia 200, cross-processed'),
 'colorslide/fuji_velvia_100_generic': ('Velvia 100', 'slide', 'Fujichrome Velvia 100'),
 'colorslide/fuji_velvia_50': ('Velvia 50', 'slide', 'Fujichrome Velvia 50'),
 'colorslide/kodak_e-100_gx_ektachrome_100': ('Ektachrome E100', 'slide', 'Kodak Ektachrome E100GX'),
 'colorslide/kodak_ektachrome_100_vs': ('Ektachrome VS', 'slide', 'Kodak Ektachrome 100VS'),
 'colorslide/kodak_elite_chrome_200': ('EliteChrome 200', 'slide', 'Kodak Elite Chrome 200'),
 'colorslide/kodak_elite_chrome_400': ('EliteChrome 400', 'slide', 'Kodak Elite Chrome 400'),
 'colorslide/kodak_elite_extracolor_100': ('Elite ExtraCol', 'slide', 'Kodak Elite ExtraColor 100'),
 'colorslide/kodak_kodachrome_200': ('Kodachrome 200', 'slide', 'Kodak Kodachrome 200'),
 'colorslide/kodak_kodachrome_25': ('Kodachrome 25', 'slide', 'Kodak Kodachrome 25'),
 'colorslide/kodak_kodachrome_64': ('Kodachrome 64', 'slide', 'Kodak Kodachrome 64'),
 'colorslide/lomography_x-pro_slide_200': ('Lomo X-Pro 200', 'slide', 'Lomography X-Pro Slide 200'),
 'colorslide/polaroid_polachrome': ('Polachrome', 'slide', 'Polaroid Polachrome'),
 'negative_color/agfa_ultra_color_100': ('Agfa Ultra 100', 'neg', 'Agfa Ultra Color 100'),
 'negative_color/agfa_vista_200': ('Agfa Vista 200', 'neg', 'Agfa Vista 200'),
 'negative_color/fuji_superia_200': ('Superia 200', 'neg', 'Fujicolor Superia 200'),
 'negative_color/fuji_superia_hg_1600': ('Superia HG 1600', 'neg', 'Fujicolor Superia HG 1600'),
 'negative_color/fuji_superia_reala_100': ('Superia Reala', 'neg', 'Fujicolor Superia Reala 100'),
 'negative_color/fuji_superia_x-tra_800': ('Superia X-Tra', 'neg', 'Fujicolor Superia X-Tra 800'),
 'negative_color/kodak_ektar_100': ('Ektar 100', 'neg', 'Kodak Ektar 100'),
 'negative_color/kodak_elite_100_xpro': ('Elite 100 XPro', 'neg', 'Kodak Elite 100, cross-processed'),
 'negative_color/kodak_elite_color_200': ('Elite Color 200', 'neg', 'Kodak Elite Color 200'),
 'negative_color/kodak_elite_color_400': ('Elite Color 400', 'neg', 'Kodak Elite Color 400'),
 'negative_color/lomography_redscale_100': ('Redscale 100', 'neg', 'Lomography Redscale 100'),
 'negative_new/fuji_160c': ('Fuji 160C', 'neg', 'Fujicolor Pro 160C'),
 'negative_new/fuji_400h': ('Fuji 400H', 'neg', 'Fujicolor Pro 400H'),
 'negative_new/fuji_800z': ('Fuji 800Z', 'neg', 'Fujicolor Pro 800Z'),
 'negative_new/kodak_portra_160': ('Portra 160', 'neg', 'Kodak Portra 160'),
 'negative_new/kodak_portra_400': ('Portra 400', 'neg', 'Kodak Portra 400'),
 'negative_new/kodak_portra_800': ('Portra 800', 'neg', 'Kodak Portra 800'),
 'negative_new/kodak_portra_800_hc': ('Portra 800 HC', 'neg', 'Kodak Portra 800, high contrast'),
 'negative_old/fuji_superia_100': ('Superia 100', 'neg', 'Fujicolor Superia 100'),
 'negative_old/fuji_superia_400': ('Superia 400', 'neg', 'Fujicolor Superia 400'),
 'negative_old/fuji_superia_800': ('Superia 800', 'neg', 'Fujicolor Superia 800'),
 'negative_old/fuji_superia_1600': ('Superia 1600', 'neg', 'Fujicolor Superia 1600'),
 'negative_old/kodak_portra_160_nc': ('Portra 160 NC', 'neg', 'Kodak Portra 160NC'),
 'negative_old/kodak_portra_160_vc': ('Portra 160 VC', 'neg', 'Kodak Portra 160VC'),
 'negative_old/kodak_portra_400_nc': ('Portra 400 NC', 'neg', 'Kodak Portra 400NC'),
 'negative_old/kodak_portra_400_uc': ('Portra 400 UC', 'neg', 'Kodak Portra 400UC'),
 'negative_old/kodak_portra_400_vc': ('Portra 400 VC', 'neg', 'Kodak Portra 400VC'),
 'instant_pro/fuji_fp-100c': ('FP-100C', 'instant', 'Fujifilm FP-100C'),
 'instant_pro/fuji_fp-100c_cool': ('FP-100C Cool', 'instant', 'Fujifilm FP-100C, cool'),
 'instant_pro/fuji_fp-100c_negative': ('FP-100C Neg', 'instant', 'Fujifilm FP-100C negative'),
 'instant_pro/polaroid_669': ('Polaroid 669', 'instant', 'Polaroid 669'),
 'instant_pro/polaroid_669_cold': ('Pola 669 Cold', 'instant', 'Polaroid 669, cold'),
 'instant_pro/polaroid_690': ('Polaroid 690', 'instant', 'Polaroid 690'),
 'instant_pro/polaroid_690_cold': ('Pola 690 Cold', 'instant', 'Polaroid 690, cold'),
 'instant_pro/polaroid_690_warm': ('Pola 690 Warm', 'instant', 'Polaroid 690, warm'),
 'instant_consumer/polaroid_px-100uv+_cold': ('PX-100 Cold', 'instant', 'Impossible PX-100 UV+, cold'),
 'instant_consumer/polaroid_px-100uv+_warm': ('PX-100 Warm', 'instant', 'Impossible PX-100 UV+, warm'),
 'instant_consumer/polaroid_px-680': ('PX-680', 'instant', 'Impossible PX-680'),
 'instant_consumer/polaroid_px-680_cold': ('PX-680 Cold', 'instant', 'Impossible PX-680, cold'),
 'instant_consumer/polaroid_px-680_warm': ('PX-680 Warm', 'instant', 'Impossible PX-680, warm'),
 'instant_consumer/polaroid_px-70': ('PX-70', 'instant', 'Impossible PX-70'),
 'instant_consumer/polaroid_px-70_cold': ('PX-70 Cold', 'instant', 'Impossible PX-70, cold'),
 'instant_consumer/polaroid_px-70_warm': ('PX-70 Warm', 'instant', 'Impossible PX-70, warm'),
 'instant_consumer/polaroid_time_zero_expired': ('Time Zero', 'instant', 'Polaroid Time Zero, expired'),
 'instant_consumer/polaroid_time_zero_expired_cold': ('Time Zero Cold', 'instant', 'Polaroid Time Zero, expired, cold'),
 'print/fuji_3510_constlmap': ('Fuji 3510', 'print', 'Fujicolor Positive 3510 cinema print'),
 'print/fuji_3513_constlmap': ('Fuji 3513', 'print', 'Fujicolor Positive 3513DI cinema print'),
 'print/kodak_2383_constlmap': ('Kodak 2383', 'print', 'Kodak Vision 2383 cinema print'),
 'print/kodak_2393_constlmap': ('Kodak 2393', 'print', 'Kodak Vision Premier 2393 cinema print'),
 # Film is Fun film emulation LUTs (rec709 versions); a film that's already in the list gets " FiF"
 'fif/400D/400D': ('CineStill 400D', 'neg', 'CineStill 400D'),
 'fif/50D/50D': ('CineStill 50D', 'neg', 'CineStill 50D'),
 'fif/800T/800T': ('CineStill 800T', 'neg', 'CineStill 800T'),
 'fif/Colorplus/Colorplus': ('ColorPlus 200', 'neg', 'Kodak ColorPlus 200'),
 'fif/Ektachrome/E100': ('Ektachrome FiF', 'slide', 'Kodak Ektachrome E100'),
 'fif/Ektar_100/Ektar': ('Ektar 100 FiF', 'neg', 'Kodak Ektar 100'),
 'fif/Fuji_C200/c200': ('Fuji C200', 'neg', 'Fujicolor C200'),
 'fif/Gold/Gold': ('Kodak Gold 200', 'neg', 'Kodak Gold 200'),
 'fif/Kodacolor_100/Kodacolor_100': ('Kodacolor 100', 'neg', 'Kodak Kodacolor 100'),
 'fif/Kodak_Dispo/Kodak_Dispo': ('Kodak Dispo', 'neg', 'Kodak disposable camera'),
 'fif/Phoenix_200/Phoenix': ('Phoenix 200', 'neg', 'Harman Phoenix 200'),
 'fif/Portra_160/P160': ('Portra 160 FiF', 'neg', 'Kodak Portra 160'),
 'fif/Portra_400/Portra_400': ('Portra 400 FiF', 'neg', 'Kodak Portra 400'),
 'fif/Portra_800/Portra_800': ('Portra 800 FiF', 'neg', 'Kodak Portra 800'),
 'fif/Provia_100F/Provia': ('Provia 100F FiF', 'slide', 'Fujichrome Provia 100F'),
 'fif/Superia_400/Superia_400': ('Superia 400 FiF', 'neg', 'Fujicolor Superia X-Tra 400'),
 'fif/Ultramax/Ultramax_warm': ('Ultramax 400', 'neg', 'Kodak UltraMax 400 (warm)'),
 # PARVEC 35 mm Film Recipes 1 (Lightroom presets, through lr-prep.py's model); a film already in the list gets " PV"
 'parvec/Candido_800T': ('Candido 800', 'neg', 'Candido 800'),
 'parvec/Cinestill_50D': ('CineStill50D PV', 'neg', 'CineStill 50D'),
 'parvec/Film_One_Hundred_100': ('1Hundred 100', 'neg', 'One Hundred Film 100'),
 'parvec/Fujifilm_200': ('Fujifilm 200', 'neg', 'Fujifilm 200'),
 'parvec/Kodak_Color_Plus_200': ('ColorPlus PV', 'neg', 'Kodak ColorPlus 200'),
 'parvec/Kodak_Ektar_100': ('Ektar 100 PV', 'neg', 'Kodak Ektar 100'),
 'parvec/Kodak_Gold_200': ('Kodak Gold PV', 'neg', 'Kodak Gold 200'),
 'parvec/Kodak_Portra_160': ('Portra 160 PV', 'neg', 'Kodak Portra 160'),
 'parvec/Kodak_Portra_400': ('Portra 400 PV', 'neg', 'Kodak Portra 400'),
 'parvec/Kodak_Ultramax_400': ('Ultramax PV', 'neg', 'Kodak UltraMax 400'),
 'parvec/LomoChrome_92__400': ('LomoChrome 92', 'neg', "LomoChrome Color '92"),
 'parvec/Lomography_Color_400': ('Lomo Color 400', 'neg', 'Lomography Color Negative 400'),
 'parvec/Phoenix_200': ('Phoenix 200 PV', 'neg', 'Harman Phoenix 200'),
}
SRC = lambda idn: 'parvec' if idn.startswith('parvec/') else 'fif' if idn.startswith('fif/') else 'gmic'
SKIP = {'colorslide/kodak_ektachrome_100_vs_generic', 'colorslide/kodak_kodachrome_64_generic'}
fit = {d['id']: d for p in sys.argv[1:-1] for d in json.load(open(p))}
import os
DESC = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'film-descriptions.json')))
out = []
for idn, (name, grp, full) in NAMES.items():
    assert len(name) <= 15 and name.isascii(), name
    d = fit[idn]
    if d['after'] > 8:                 # the OM-3 controls can't make it (heavy fading, colour casts by brightness)
        print('left out', name, d['after']); continue
    out.append({'name': name, 'group': grp, 'film': full, 'src': SRC(idn), 'desc': DESC[name], 'de': d['after'], 'hue': d['hue'], 'light': d['light'], 'sat': d['sat'],
                'tone': d['tone'], 'contrast': d['contrast'], 'wb': d['wb']})
missing = set(fit) - set(NAMES) - SKIP
assert not missing, missing
names = [f['name'] for f in out]; assert len(set(names)) == len(names), 'duplicate names'
json.dump({'source': "Fitted with webapp/scripts/fit-luts.ts to the G'MIC film emulation LUTs, the Film is Fun film emulation "
           "LUTs and (through lr-prep.py's Lightroom model) the PARVEC 35 mm Film Recipes 1 presets; settings only.",
           'films': out}, open(sys.argv[-1], 'w'), separators=(',', ':'))
print(len(out), 'films; mean ΔE', round(sum(f['de'] for f in out) / len(out), 2), 'worst', max((f['de'], f['name']) for f in out))
