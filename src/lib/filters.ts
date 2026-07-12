// List-page search + filters. Pure functions, filtered in memory over the
// already-loaded list so the behavior is identical for the Postgres backend
// and the no-DB seed fallback (one code path, §11). At the current WNY scale
// (~100 listings) this is deliberate — push down to SQL only when the data
// outgrows it, not before (§3: no scale assumptions in the MVP).
//
// Filters only ever NARROW what is shown. They never touch claim states or
// labels (§4) — a filtered list shows the same honest cards, just fewer.
import type { Listing, ListingKind } from './types';
import { isCategory, type Category } from './categories';

// How the (already-filtered) list is ordered. Sorting only REORDERS — it never
// narrows or touches claim labels (§4).
//   name   — case-insensitive by name (the default; what the list always showed)
//   zip    — by postal code, groups a neighborhood together (§3 WNY-first)
//   recent — newest submissions first, so fresh community listings are findable
//   distance — nearest to the visitor. Needs the visitor's location AND listing
//     coordinates, so it CANNOT be computed on the zero-JS server (§5). It is a
//     CLIENT-ONLY sort: the progressive-enhancement script reorders on-device
//     (location never leaves the device, §6). On the server it falls back to
//     name order, and the "Distance" affordance is added by that script — no-JS
//     visitors never see an option that can't work.
export type SortKey = 'name' | 'zip' | 'recent' | 'distance';
export const DEFAULT_SORT: SortKey = 'name';
const SORT_KEYS = new Set<SortKey>(['name', 'zip', 'recent', 'distance']);

export interface ListingFilters {
  /** Free-text needle, matched case-insensitively against name/summary/city. */
  q: string;
  category: Category | null;
  /** Exact `region` match ("Erie County"). Options come from the live data. */
  county: string | null;
  /** Representation axis (§1) — valid on both kinds, independent flags. */
  owned: boolean;
  led: boolean;
  /** Provider competence axis — providers only; ignored for places. */
  literate: boolean;
  /** ZIP-code prefix, digits only. Matches listings whose postal code STARTS
      with it, so "142" is the Buffalo area and "14222" is one exact ZIP. */
  zip: string;
  /** Result ordering. Not a "filter" (it never narrows) — see hasActiveFilters. */
  sort: SortKey;
}

// Query-param names are part of the page's URL contract (bookmarkable,
// zero-JS GET form). Keep them short and stable.
export function parseListingFilters(params: URLSearchParams): ListingFilters {
  const rawCategory = params.get('category');
  return {
    // Cap the needle so a hostile query string can't balloon the page.
    q: (params.get('q') ?? '').trim().slice(0, 120),
    category: rawCategory && isCategory(rawCategory) ? rawCategory : null,
    county: (params.get('county') ?? '').trim().slice(0, 80) || null,
    owned: params.get('owned') === '1',
    led: params.get('led') === '1',
    literate: params.get('literate') === '1',
    // Digits only (a ZIP is numeric), capped — a stray query can't balloon it.
    zip: (params.get('zip') ?? '').replace(/\D/g, '').slice(0, 5),
    // Only a known key is honored; anything else falls back to the default order.
    sort: parseSort(params.get('sort')),
  };
}

function parseSort(raw: string | null): SortKey {
  return raw && SORT_KEYS.has(raw as SortKey) ? (raw as SortKey) : DEFAULT_SORT;
}

// Sort is intentionally excluded: it reorders, it doesn't narrow, so a list
// sorted by zip with no filters is still "All N places", not a filtered subset.
export function hasActiveFilters(f: ListingFilters, kind: ListingKind): boolean {
  return Boolean(
    f.q ||
      f.category ||
      f.county ||
      f.zip ||
      f.owned ||
      f.led ||
      (kind === 'provider' && f.literate),
  );
}

export function applyListingFilters(listings: Listing[], f: ListingFilters): Listing[] {
  const needle = f.q.toLowerCase();
  return listings.filter((l) => {
    if (needle) {
      const hay = `${l.name} ${l.summary ?? ''} ${l.city ?? ''}`.toLowerCase();
      if (!hay.includes(needle)) return false;
    }
    if (f.category && l.category !== f.category) return false;
    if (f.county && l.region !== f.county) return false;
    // ZIP is a PREFIX match: "142" keeps the whole Buffalo area, "14222" one ZIP.
    if (f.zip && !(l.postalCode ?? '').startsWith(f.zip)) return false;
    if (f.owned && !l.disabledOwned) return false;
    if (f.led && !l.disabledLed) return false;
    if (f.literate && !l.provider?.disabilityLiterate) return false;
    return true;
  });
}

// Reorder the (already-filtered) list. Returns a NEW array — never mutates the
// caller's. Every branch breaks ties by name so the order is stable and
// deterministic across the DB and seed paths (§11). Missing values sink to the
// bottom (a listing with no ZIP / no date shouldn't jump to the top).
//
// 'distance' is NOT computed here — the server has no visitor location (§5). It
// falls back to name order; the client enhancement does the real distance
// reorder on-device (§6). See SortKey.
export function sortListings(listings: Listing[], sort: SortKey): Listing[] {
  const byName = (a: Listing, b: Listing) =>
    a.name.localeCompare(b.name, undefined, { sensitivity: 'base' });

  if (sort === 'zip') {
    return [...listings].sort((a, b) => {
      const az = a.postalCode?.trim() ?? '';
      const bz = b.postalCode?.trim() ?? '';
      if (az !== bz) {
        if (az === '') return 1; // missing zip sinks to the bottom
        if (bz === '') return -1;
        return az.localeCompare(bz, undefined, { numeric: true });
      }
      return byName(a, b);
    });
  }

  if (sort === 'recent') {
    // Newest first, by createdAt (ISO strings compare chronologically). Rows
    // with no date go last, ties broken by name.
    return [...listings].sort((a, b) => {
      const ad = a.createdAt ?? '';
      const bd = b.createdAt ?? '';
      if (ad !== bd) {
        if (ad === '') return 1;
        if (bd === '') return -1;
        return bd.localeCompare(ad); // descending = newest first
      }
      return byName(a, b);
    });
  }

  // 'name' and the server fallback for 'distance'.
  return [...listings].sort(byName);
}

// Distinct counties present in the loaded data, Erie first (§3 beachhead),
// the rest alphabetical. Derived from data so the dropdown never offers a
// county with zero listings.
export function countyOptions(listings: Listing[]): string[] {
  const seen = new Set<string>();
  for (const l of listings) if (l.region) seen.add(l.region);
  const counties = [...seen].sort((a, b) => a.localeCompare(b));
  const erie = counties.indexOf('Erie County');
  if (erie > 0) {
    counties.splice(erie, 1);
    counties.unshift('Erie County');
  }
  return counties;
}
