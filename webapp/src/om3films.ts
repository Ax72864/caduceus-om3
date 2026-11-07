// The film sims for the OM-3: looks fitted to film-emulation LUTs (scripts/fit-luts.ts; the data file holds only the
// fitted settings). Each becomes an ordinary OM-3 look: Hue / Light / Saturation per sector, Highlights / Shadows /
// Midtones, Blacks / Whites, Contrast and the WB shift. `de` is the fit's mean ΔE76 against the LUT in the preview
// model (lower = closer).
import filmsJson from './data/om3films.json';
import { blankLook, type Look } from './pack';

export interface Film {
  name: string; group: FilmGroup; film: string; de: number;
  hue: number[]; light: number[]; sat: number[];
  tone: Look['tone']; contrast: number; wb: { a_b: number; g_m: number } | null;
}
export type FilmGroup = 'fuji' | 'slide' | 'neg' | 'instant' | 'print';
export const FILM_GROUPS: [FilmGroup, string][] = [
  ['fuji', 'Fujifilm simulations'], ['slide', 'Slide film'], ['neg', 'Colour negative'], ['instant', 'Instant film'], ['print', 'Cinema print'],
];
export const FILMS = (filmsJson as { films: Film[] }).films;

/** How close the fit is, in words. */
export const fitLabel = (de: number) => (de < 3 ? 'very close' : de < 4.5 ? 'close' : de < 6 ? 'approximate' : 'loose');

/** The film as an OM-3 look (no grain or Extras: those stay the user's choice). */
export function filmLook(f: Film): Look {
  const l = blankLook('colour', f.name);
  l.hue = [...f.hue]; l.light = [...f.light]; l.sat = [...f.sat];
  l.tone = { ...f.tone };
  l.advice = { contrast: f.contrast, sharpness: 0 };
  l.wb = f.wb ? { ...f.wb } : null;
  l.notes = `${f.film}. Fitted to a film emulation LUT (${fitLabel(f.de)} match).`;
  return l;
}
