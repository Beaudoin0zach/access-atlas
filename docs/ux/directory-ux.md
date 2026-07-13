# Access Atlas — Directory UX & Interaction Design

Status: living document, first written 2026-07-13. This is the app-specific UX spec for
Access Atlas, derived from the BAS platform standard
([`bas-platform/docs/design-principles.md`](https://github.com/Beaudoin0zach/bas-platform/blob/main/docs/design-principles.md))
and grounded in the code that already exists in this repo. It is implementation-oriented:
every requirement below names the file it lives in (or should live in) for an Astro,
**zero-JS** static/SSR stack.

> Companion to [`CLAUDE.md`](../../CLAUDE.md) (the project constitution — the Non-Negotiables
> and the §4 validation model override convenience) and
> [`docs/design-direction.md`](../design-direction.md) (the evidence base). Where those define
> *what Access Atlas is*, this defines *how the browsing and contribution surfaces should behave*.

---

## 0. Scope — what applies and what doesn't

The platform standard was written mostly around a real-time messaging/assistant shape. **Access
Atlas is not a chat app.** It is a list-first accessibility directory that ships near-zero client
JS by default (Astro static + on-demand SSR; `astro.config.mjs`). So the standard applies
selectively:

| Platform §            | Applies here? | Why |
|-----------------------|:---:|---|
| §1 Navigation         | ✅ **Core** | Multi-page, deep-linkable directory; browser Back and "you are here" are the spine. |
| §3.1 Send behavior    | ❌ N/A | No message composer. The only "send" is a plain form POST (contribution) — covered under §3.4 error states, not send-status state machines. |
| §3.2 Typing & presence| ❌ N/A | No live collaboration, no other users to signal presence for. Zero-JS forbids the debounced live cues anyway. |
| §3.3 Login/onboarding | ⚠️ **Partial** | There is *no browsing onboarding* — browsing is account-free by design. Login applies only at the contribution boundary (§4 below). |
| §3.4 Empty & error    | ✅ **Core** | Search empty-results coaching + graceful no-JS / offline behavior are top-value surfaces. |
| §4 Accessibility spine| ✅ **Core**, reframed | The dynamic-status live-region machinery is mostly N/A (nothing streams). What carries over: contrast verified in **both** themes, visible focus, no color-only cues. The zero-JS constraint is itself the a11y asset. |
| §2 Delight layer      | ✅ but **intentionally minimal** | See §5. Restraint is the design position, not an omission. |

The four surfaces this doc owns, in priority order: **navigation**, **search empty/error states**,
**the login boundary**, **contrast + the zero-JS-as-a11y-asset stance**.

---

## 1. Navigation — resilient, zero-JS, place-preserving

**Principle (platform §1):** never trap the user; browser Back must work and preserve place;
always show "you are here." On a zero-JS stack this is *easier to get right* than on an SPA —
there is no client router to break history, no scroll restoration to re-implement, no focus to
manually manage across route changes. The job is to not squander that.

### 1.1 The URL is the application state

Every browsing surface must be a real, GET-addressable URL. This is already the architecture and
it is non-negotiable:

- **List + filter state lives entirely in the query string.** `ListingFilters.astro` is a plain
  `<form method="get">`; applying filters navigates to `/places/?q=…&category=…&county=…`. Results
  are therefore bookmarkable, shareable, and — critically — **a native history entry**. Do not
  move filter state into `sessionStorage`, a cookie, or a client island; that would desync Back.
- **The Place/Provider distinction and the submit-flow kind are link-driven** (`?kind=place` in
  `contribute/submit.astro`), not JS tab-swaps, precisely so each state is its own URL and Back
  steps between them.
- **On-demand rendering (`prerender = false`) is for freshness and saved a11y settings, not
  interactivity.** It still ships zero JS (`astro.config.mjs` comment makes this explicit). Keep
  it that way: SSR here means "server-rendered HTML per request," never "hydrated client route."

**Implementation rule:** any new browse/filter/sort control is added as a native form control
inside the existing GET form (`ListingFilters.astro`) or as an `<a href>`. If you are ever tempted
to reach for `onclick` to change what the list shows, the answer is a link or a form field.

### 1.2 Browser Back preserves place — by construction

Because state is in the URL and pages are server-rendered from that URL:

- Back from a listing detail (`/places/[id]`) to the filtered list returns to the **same filtered,
  sorted list** the user came from, because that list was its own URL in history. This satisfies
  the platform's "Back returns to where the user *came from*, not a fixed parent."
- The browser restores scroll position natively on Back/Forward for server-rendered documents. Do
  not add JS scroll handling — it can only regress this.
- The `/nearby.js` progressive-enhancement script (on-device distance sort, list pages only) must
  never write to `history` or mutate the URL in a way that creates phantom entries. Its job is to
  reorder already-rendered DOM; keep it side-effect-free with respect to navigation. (CSP scopes
  `script-src 'self'` to exactly the two list routes — `src/lib/security.ts` — so this stays the
  *only* script, and it degrades to "no distance sort" when JS is off.)

**Regression guard:** a Playwright check that loads `/places/?q=cafe&category=food`, clicks the
first result, presses Back, and asserts the URL and the visible result set are unchanged. This is
the one navigation behavior most likely to silently break if someone islands the list.

### 1.3 "You are here" — three levels

The platform asks for active-tab highlight + screen titled. Access Atlas needs three concrete
affordances, and one of them is currently a **gap to close**:

1. **Page title** — already correct. `Base.astro` renders `{title} — Access Atlas` and each page
   passes a specific title. Keep every new route titled; the `<title>` is the primary "where am I"
   for screen-reader and tab users.

2. **Active primary-nav item — GAP.** The primary nav (`Base.astro`, `<nav aria-label="Primary">`)
   currently renders all links identically; there is no `aria-current`. **Add
   `aria-current="page"` to the nav link matching the current section**, and a matching visible
   style (weight + a non-color cue such as an underline or left-border, never color alone —
   platform §4 / WCAG 1.4.1). Zero-JS implementation: `Base.astro` already has `Astro.url.pathname`
   at render time —

   ```astro
   ---
   // in Base.astro, before the nav
   const path = Astro.url.pathname;
   const isSection = (href) => path === href || path.startsWith(href);
   const NAV = [
     { href: '/places/', label: 'Places' },
     { href: '/providers/', label: 'Providers' },
     { href: '/contribute/submit/', label: 'Suggest a listing' },
     { href: '/about/help/', label: 'Help' },
     { href: '/settings/', label: 'Accessibility' },
     { href: '/about/privacy/', label: 'Privacy' },
   ];
   ---
   <ul>
     {NAV.map(({ href, label }) => (
       <li>
         <a href={href} aria-current={isSection(href) ? 'page' : undefined}>{label}</a>
       </li>
     ))}
   </ul>
   ```

   Style `a[aria-current="page"]` in `global.css` with a bottom-border/weight change that survives
   `.contrast-high` and `.underline-links`. This is a small, high-value change and it costs zero JS.

3. **Back-to-list affordance on detail pages — present, standardize it.** Detail and sub-pages
   already carry a "← All places" / "← Back to …" link (`places/[id].astro`, `providers/[id].astro`,
   `account/delete.astro`, `contribute/confirm/[claimId].astro`). This is the right pattern for a
   shallow hierarchy — a full breadcrumb trail would be over-engineered for a two-level directory.
   Standardize it: **every non-root page has a single, first-in-`<main>`, text-labeled back link
   pointing at its section index.** Because it is a real `<a href>` to the section root (not
   `history.back()`), it works even on a cold deep-link where there is no Back to go to — which a
   JS `history.back()` would get wrong. Keep using an `<a href>`, not a script.

### 1.4 Never trap; every page reachable and escapable

- The skip link (`Base.astro`, first focusable element → `#main`) is the keyboard user's "escape to
  content." Keep it the first focusable element on every page; it is inherited via the layout, so
  the rule is simply "every page uses `Base.astro`."
- The `<details>` filter disclosure (`ListingFilters.astro`) is native — Esc/Enter/Space behavior
  and focus are the browser's, not ours, and it works with JS off. Do not replace it with a scripted
  accordion.
- There are no modals in the browsing flow, and there should not be — a zero-JS static page has no
  honest way to trap-and-restore focus for a modal. Prefer a dedicated page or a `<details>`
  disclosure over any dialog pattern. If a real dialog is ever unavoidable, it forces a scripted
  island and must ship the full focus-trap + Esc + return-focus contract; treat that as a
  significant deviation to be reviewed, not a default.

---

## 2. Search & empty/error states (platform §3.4)

**Principle:** every empty screen is onboarding — coach, don't leave it blank; error copy is
plain-language, blame-free, recovery attached, user input preserved. Access Atlas has two distinct
"nothing to show" situations and they must **not** share copy.

### 2.1 Two empty states, never conflated

`places/index.astro` already distinguishes these; this is the standard, and `providers/index.astro`
must match it:

- **Genuinely empty (no active filters, list is just sparse).** This is the *first-run onboarding*
  screen. It must explain *why* it's sparse and give a forward action — not apologize. Current copy
  is the model:
  > **No places here yet.** Access Atlas is starting in Buffalo / Erie County, and this directory
  > grows from real first-person visits — so it's sparse on purpose until the community fills it in.
  > [Suggest an accessible place], or browse [providers] instead.

  The sparseness is honest and mission-consistent (§4 "nothing about us without us" — the directory
  is community-built, not scraped). Keep that framing.

- **Empty *because of filters* (a search returned nothing).** This is the coaching case the platform
  §3.4 cares about most. Requirements:
  1. **Say why**: state that the *filters*, not the directory, produced zero results — "No places
     match these filters."
  2. **Suggest broader queries — specifically, not generically.** The current "remove a filter or
     clear all" is the floor. Raise it: tell the user *which* of their active constraints is the
     narrowing one, and offer one-click widenings. Because filter state is in the URL, each
     suggestion is just a link with one param dropped:
     - "No results in **ZIP 14222**. [See all of **Erie County**](/places/?county=Erie+County) ·
       [Clear the ZIP filter](/places/?q=…&category=…) *(other filters kept)*."
     - If a text query is the only constraint: "Nothing matched **"{q}"**. Try a shorter or more
       general word, or [browse all places](/places/)."
     Build these links from the parsed filters (`src/lib/filters.ts`) so each preserves the *other*
     active filters and only relaxes one. This is the zero-JS equivalent of query suggestions.
  3. **Preserve the query.** The search box (`ListingFilters.astro`, `value={filters.q}`) already
     re-renders the user's text on the results page — never clear it. The filter panel must stay
     **open** when a filter is active (`panelOpen` logic) so the user can see and edit exactly what
     produced zero results; a collapsed panel over an empty list reads as "the directory is empty,"
     which is a lie.

- **Result-count heading is a status message.** The `<h2>` results heading ("N of M places match
  your filters" vs. sr-only "All M places") is how a screen-reader user perceives that a filter
  reload changed the set, without any live region. Keep it a real heading in the `h1 → h2 → h3`
  outline so heading-navigation lands on it after every filter submit. This is the zero-JS
  substitute for the platform's `aria-live` status pattern — the page reload *is* the announcement,
  and the heading is what gets announced.

### 2.2 Search input ergonomics (platform §1 input rules that do apply)

- **Label above the field, never placeholder-as-label** — `ListingFilters.astro` already labels
  every control; the ZIP `placeholder="e.g. 14222"` is an *example alongside* its real label, which
  is the allowed use.
- **≥16px font on inputs** (platform §1 — prevents mobile-Safari zoom-on-focus). Verify the filter
  inputs inherit this from `global.css`; do not set a smaller font on `.filter-grid input`.
- **Right keyboard per field**: ZIP uses `inputmode="numeric"` (not `type="number"`, which would add
  spinners and strip leading zeros) — keep this; it's already correct.
- **Explicit submit, never auto-apply** (matches GOV.UK/MOJ "filter a list", `design-direction.md`
  §3). The zero-JS `<form>` with an "Apply filters" button is exactly this — do not add a
  `change`-listener that auto-navigates, even as an enhancement; it breaks the "review before you
  commit" model and would need JS.

### 2.3 No-JS, offline, and error behavior

The platform §3.4 offline pattern (persistent banner + local queue + flush-on-reconnect) is a
**chat construct and does not port** — there is nothing to queue on a directory read, and we ship no
service worker or client store. What "graceful degradation" means *here*:

- **JS off is a first-class, fully-supported mode, not degraded.** Every browsing and contribution
  path works with `script-src 'none'` (the CSP default; `Base.astro` + `src/lib/security.ts`). The
  *only* JS on the whole site is `/nearby.js` on the two list pages, and its absence removes exactly
  one feature: the "Distance (nearest)" sort option, which is why that option is injected by the
  script and **not** rendered server-side (`ListingFilters.astro` comment). No other feature may be
  built such that turning JS off removes it. If a feature can't work without JS, it needs an explicit
  deviation review — the zero-JS budget is treated as existential (CLAUDE.md §2/§5).

- **Offline (network gone) is the browser's story to tell, and that's the honest one.** With no
  service worker, an offline navigation shows the browser's native offline page. Do **not** add a
  service-worker offline cache to "fix" this unless it is designed and reviewed as a deliberate
  feature — a half-built SW is a worse failure mode (stale data on a *safety-relevant* directory)
  than the browser's clear "you're offline." If offline support is ever pursued, it must respect the
  §4 freshness guarantee (never serve a stale claim state as current) and stay within the no-tracking
  line (§6).

- **Form-POST errors: server-rendered, inline, input preserved.** The contribution form is the one
  write path, and its error handling is the model to follow for any future POST
  (`contribute/submit.astro`): the endpoint 303-redirects back to the form with a `?status=…` code;
  the page maps that code to a **plain-language, blame-free** banner (`BANNERS` map) *and*, where the
  error belongs to a field, sets `aria-invalid` + `aria-describedby` and `autofocus` on that field so
  the message sits where the fix is made (`nameError`, `coordsError`). Requirements for any new error:
  - Copy names the problem and the recovery, never blames the user, and never shows a raw
    stack/500. ("Something went wrong and your listing was not saved. Please try again." is the
    floor.)
  - **User input is preserved on error.** Re-render submitted values server-side on the redirect-back
    so a validation bounce never makes someone retype. (This mirrors the platform's "on failed login,
    preserve the username.")
  - Field-level errors get `role`-appropriate delivery: a submit that failed validation uses an
    `alert` banner (assertive) for the summary; a "not saved because sign-in required" uses a
    `status`/`alert` per its urgency (see the existing `BANNERS` roles).

---

## 3. The login boundary — browse free, contribute pseudonymously

**Principle:** browsing is account-free; identity gates *contribution only*; and when it does gate,
the identity is **pseudonymous** (ADR-003 pairwise subject IDs). There is no "registration wall" and
no browsing onboarding to interrupt.

### 3.1 Browsing never touches identity

This is a hard line, already enforced in code and to be kept:

- No browse route reads auth config or a session. The OIDC config module states it outright: "Public
  browsing never touches this … identity gates contribution only" (`src/lib/auth/config.ts`). A
  reader can hit `/`, `/places/`, `/providers/`, `/places/[id]`, `/settings/`, `/about/*` with **no
  cookie, no account, no redirect**.
- **Do not add a login affordance to the primary nav or any browse page.** The header nav
  (`Base.astro`) deliberately has no "Sign in" link. Login appears *only* where a write is attempted.
  Adding a global "Sign in" would signal an account is expected for browsing, which is the exact
  anti-pattern this app rejects.
- Accessibility settings (`/settings/`) are **account-free too** — they persist in a first-party
  functional cookie read server-side (`src/lib/settings.ts`), never a user profile. A person gets
  their full customized, accessible experience with zero identity. This is deliberate and
  load-bearing: the most access-dependent users get the most tailoring for the least exposure.

### 3.2 Login appears only at the contribution boundary

The seam is `contributionAccess()` (`src/lib/contributor.ts`); the boundary pages are
`contribute/submit.astro` and `contribute/confirm/[claimId].astro`. The UX contract:

- The sign-in prompt is rendered **on the contribution surface, next to the thing being contributed**
  — not as a gate in front of it. Even when not signed in, **the form is still shown** ("You can
  still see the form below." / "To add a listing, please sign in to contribute. Browsing stays
  account-free."). The user sees what they're being asked to sign in *for* before deciding. Preserve
  this "form-visible, sign-in-adjacent" layout for any new contribution flow.
- Sign-in is a **plain link to a server route** (`/api/auth/login?return_to=…`), not a JS-driven
  modal or SPA redirect. The login endpoint mints PKCE verifier + CSRF `state` server-side, sets
  short-lived httpOnly cookies, and 302s to Keycloak's hosted login — "The browser never handles a
  token" (`src/pages/api/auth/login.ts`). Zero client JS in the auth flow; keep it that way.
- **`return_to` brings the user back to exactly where they were** (`sanitizeReturnTo`), so signing in
  is a detour, not a context loss — the platform "Back returns where you came from" principle applied
  to the auth round-trip.
- The three access states each get honest, distinct copy (already implemented in
  `contribute/submit.astro`): `keycloak + not signed in` → invite to sign in (browsing stays
  account-free); `keycloak + signed in` → "You're signed in and contributing **pseudonymously**" +
  sign-out; `closed` → contributions not open yet, form still visible. Keep the word *pseudonymously*
  visible to the signed-in contributor — it is a promise the UI should state, not bury.

### 3.3 The identity is pseudonymous — and the UI must not undercut it (ADR-003)

[ADR-003](https://github.com/Beaudoin0zach/bas-platform/blob/main/docs/adr/003-pairwise-subject-identifiers.md)
mandates **pairwise** subject identifiers: Access Atlas receives its *own* opaque, app-specific
`sub` for a user — no other BAS app (KindredAccess, the benefits navigator) can correlate that this
is the same human from tokens or data. That is a data-layer decision, but it carries UX obligations:

- **Contributors are keyed by the pairwise `sub`, and the app stores nothing that re-identifies
  them.** The contributor record is created from the `sub` with an optional self-chosen *pseudonym*
  (`getOrCreateContributorBySub`, `src/lib/contributor.ts`) — never a real name pulled from the IdP.
  Any future "contributor profile" surface must show the pseudonym only; do not surface email, legal
  name, or anything the token might carry.
- **Never display or link cross-app identity.** Because there is no shared `sub`, there is nothing to
  join on — and the UI must never invite the user to "connect your KindredAccess account" or show
  "you also contribute to X." ADR-003 is explicit that cross-app "same user" features must go through
  explicit, consented, IdP-mediated linkage; there are none today, so the correct UI is *silence* on
  the subject.
- **State pseudonymity plainly at the point of contribution** (the "contributing pseudonymously" copy
  above). This is not legalese — for a directory built by disabled people about disability access, "my
  contribution can't be tied back to me across the portfolio" is a trust primitive, and the UI should
  say it in plain words at the moment it matters.
- **Sign-out is immediate and honest.** The app session is a revocable DB row, not a bare JWT
  (`src/lib/auth/session.ts`); logout revokes it server-side. The UI's sign-out control is a real
  form POST (`/api/auth/logout`), zero JS. Keep it visible whenever signed in.

> **Provisional stand-in note.** Locally/preview, a cookie pseudonym stands in for Keycloak, hard-gated
> by `ALLOW_PROVISIONAL_CONTRIBUTIONS` (`src/lib/contributor.ts`). It is explicitly *not* an anti-abuse
> control and must never ship enabled to production. The UX above is written for the real Keycloak path;
> the provisional path should present the same "browse free / contribute pseudonymously" language so the
> boundary behaves identically in dev.

---

## 4. Accessibility — contrast in both themes, and zero-JS as the asset

**Principle (platform §4):** contrast ≥ 4.5:1 text / 3:1 large text & UI, **verified in both light
and dark themes**; visible focus everywhere; status conveyed as text/shape, never color or animation
alone. The platform's live-region/dynamic-status machinery is mostly N/A here (a static directory has
no typing/send/presence/connectivity cues to announce) — so §4 reduces, for Access Atlas, to
**contrast, focus, color-independence, and preserving the zero-JS property that makes all of it hold.**

### 4.1 Contrast is verified in both themes — and contrast is an independent axis

- Every text/background pairing is chosen against WCAG 2.2 AA in **both** palettes, with the measured
  ratios recorded inline in `src/styles/global.css` (light `:root`: fg ~15:1, muted ~7.6:1, link
  ~6.2:1, brand text ~7.9:1; dark `:root.theme-dark`: re-pointed tokens documented as ~8:1 muted, ~7:1
  link, etc.). **Any new token or color must land with its ratio verified in both themes before
  merge** — this is the "born passing" discipline the platform standard opens with. Do not introduce a
  raw hex in a component; pull from the tokens so both themes and high-contrast inherit it.
- **Theme is user-selectable, not just OS-following** (`system` / `light` / `dark`, `settings.ts` +
  `global.css`) — a person on a device whose OS scheme fights their need can override it. The dark
  token block is duplicated across the explicit `.theme-dark` class and the `prefers-color-scheme`
  media query *on purpose* (a class selector and an `@media` can't be comma-joined) — **keep the two
  blocks in sync**; a drift there means the OS-dark and toggled-dark users see different contrast.
- **High contrast is an independent axis from light/dark** (Access Atlas diverges from KindredAccess,
  which folds contrast into one theme enum — `design-direction.md` §2, CLAUDE.md §15: the
  more-accessible option wins). So four combinations must each be contrast-verified: light,
  light+contrast (black-on-white), dark, dark+contrast (white-on-dark). `global.css` already scopes
  each so contrast never paints black-on-dark or white-on-light — preserve that scoping when touching
  these rules.
- **`--field-border` is a separate, darker token than the decorative `--color-border`** because
  interactive control borders must clear WCAG 1.4.11 (≥3:1) while hairlines needn't. Keep interactive
  borders on `--field-border`; don't "tidy" them onto the decorative token.
- **The a11y gate is CI, not vibes**, but automated scanners catch only ~40% (README, CLAUDE.md §5).
  `npm run test:a11y` (Playwright + axe-core) must pass, **and** manual AT passes (NVDA, VoiceOver,
  keyboard-only — see `docs/manual-*-testing.md`) are required before shipping a user-facing surface.
  Run the contrast check in **both** themes and with high-contrast on — axe defaults to one theme and
  will miss a dark-mode regression.

### 4.2 Color is never the only signal

Directly from platform §4 / WCAG 1.4.1, and already the house rule: the validation tones
(`--tone-verified/-sourced/-partial/-unverified/-disputed`) are **never used as color alone** — every
trust badge also carries a text label and a leading mark glyph (`global.css` comment; `LabelBadge.astro`;
all trust strings come from `src/lib/labeling.ts`, never hand-written in a component). Keep this: any
new state that uses a tone color ships with a text label and a non-color mark. The optional
**underline-links** setting exists for the same reason — some users can't rely on color to see a link
(`settings.ts`, `.underline-links`); ensure new link styles honor it.

### 4.3 Focus is always visible

Platform §4 (SC 2.4.11 / 2.4.13): every interactive element shows a visible focus indicator, including
on the teal header where a default ring would vanish — hence the dedicated `--header-focus` / `--color-focus`
tokens (`global.css`). Never remove an outline without replacing it with an equal-or-better visible
indicator, and check it survives high-contrast (where border tokens flip to pure black/white).

### 4.4 The zero-JS constraint is an accessibility asset — keep it

This is the design position, stated plainly so it isn't "optimized away" later:

- **Zero-JS *is* the a11y strategy, not a limitation we tolerate.** Semantic server-rendered HTML with
  native controls (native `<details>`, native `<form>`, native `<select>`, real `<a href>` links)
  hands the browser and assistive tech the accessibility they already implement correctly — no
  hand-rolled widget can match a native `<select>`'s screen-reader and keyboard behavior across
  platforms. It also means **low bandwidth and low CPU**, which is itself an access dimension for
  users on old devices, metered data, or assistive setups that choke on heavy JS (CLAUDE.md §2/§5
  treats this budget as existential).
- **The CSP self-enforces it.** `script-src 'none'` site-wide, relaxed to `'self'` on exactly the two
  list routes for `/nearby.js` (`src/lib/security.ts`, route-aware, mirrored in the `Base.astro` meta
  tag and the SSR header via `src/middleware.ts`). This means a stray inline `<script>` or third-party
  embed **won't execute** — the accessibility property is protected by policy, not discipline alone.
  Do not widen the CSP to add a script without an ADR: every script is a potential a11y and
  low-bandwidth regression, and a tracking vector the no-analytics stance (§6/§14) forbids.
- **Interactivity is added as progressive enhancement over a working baseline, or not at all.**
  `/nearby.js` is the template: the page is fully usable without it; it enhances one sort; it keeps the
  user's location on-device (§6); and the feature it adds is the one that *honestly requires* a
  capability (geolocation) the server doesn't have. Where a React island is genuinely needed for a
  contributor flow, use `react-aria-components` (never a hand-rolled widget — README/§9) and keep the
  island as small as the flow allows; do not convert whole pages to client rendering.
- **When in doubt, the HTML-only path wins.** If a proposed interaction can't be expressed as a link,
  a form, or a `<details>`, the first question is whether it should exist on a directory at all —
  before it's whether to ship JS for it.

### 4.5 Reduced motion and the delight layer

`reduce-motion` is a user setting that forces reduced motion regardless of the OS (`settings.ts`,
`.reduce-motion` in `global.css`), on top of honoring `prefers-reduced-motion`. Any animation ever
added must have a reduced-motion path (platform §2 gate) — but see §5: there is very little to reduce
here, on purpose.

---

## 5. The delight layer — deliberately minimal

Platform §2 says micro-interactions lift retention *when earned*. Access Atlas's earned position is
**restraint**: the audience includes people for whom motion, surprise, and decorative flourish are
access *barriers*, not delight. So the delight budget is spent on calm, not celebration.

- **No celebrations, no presence pulses, no optimistic-UI shimmer** — most of the platform §2 patterns
  are chat-shaped and absent here by design, not omission.
- The delight that *is* present is quiet and functional: the themed light/dark palette (a comfort
  affordance, not a flourish), gentle card `:hover` lift on pointer devices (dropped under
  `.reading-mode`, `global.css`), and the `reading-mode` setting that *removes* decoration (narrower
  measure, flat surfaces, no hover lift) for users who need focus (WAI-COGA). The premium feeling comes
  from **the page being fast, legible, honest, and never fighting the user** — not from animation.
- Any future micro-interaction must clear the platform §2 gates (purpose, <300ms, don't-repeat,
  reduced-motion path) **and** the higher local bar: it may not require JS on a browsing page, and it
  may not add motion that a motion-sensitive user can't fully disable. In practice this means most
  "delight" ideas belong nowhere on this app — and that is the correct answer.

---

## 6. Implementation checklist (per PR touching these surfaces)

- [ ] New browse/filter/sort state is a URL (GET form field or `<a href>`), not client state — Back and
      bookmarking still work.
- [ ] Every new page uses `Base.astro` (skip link, landmarks, title inherited) and passes a specific
      `<title>`.
- [ ] Primary-nav active item carries `aria-current="page"` with a non-color-only visible style (§1.3
      gap — close it).
- [ ] Non-root pages have a first-in-`<main>`, text-labeled back link that is an `<a href>` to the
      section root (works on cold deep-links).
- [ ] Filtered-empty results coach with *specific* one-param-broader links and preserve the query; the
      filter panel stays open when a filter is active.
- [ ] The results-count `<h2>` is a real heading in the `h1→h2→h3` outline.
- [ ] No login affordance on any browse page; sign-in appears only at the contribution boundary, form
      visible alongside it, via a server-route link (no JS).
- [ ] Contributor UI shows the pseudonym only; states "pseudonymously"; never surfaces cross-app
      identity (ADR-003).
- [ ] Any new color is a token, contrast-verified in **all four** of light / light+contrast / dark /
      dark+contrast; interactive borders use `--field-border`.
- [ ] Every state that uses a tone color also has a text label + non-color mark; new links honor
      `.underline-links`.
- [ ] Feature works with `script-src 'none'`; if it adds a script, that needs an ADR and a CSP change,
      and the baseline still works without it.
- [ ] `npm run test:a11y` passes **and** the manual AT/keyboard/contrast passes (both themes) are done
      before "done" (CLAUDE.md §5, `docs/manual-*-testing.md`).

---

## Sources

BAS platform standard [`design-principles.md`](https://github.com/Beaudoin0zach/bas-platform/blob/main/docs/design-principles.md)
and [`ADR-003`](https://github.com/Beaudoin0zach/bas-platform/blob/main/docs/adr/003-pairwise-subject-identifiers.md);
this repo's [`CLAUDE.md`](../../CLAUDE.md), [`docs/design-direction.md`](../design-direction.md), and the
implementation files cited throughout (`src/layouts/Base.astro`, `src/lib/settings.ts`,
`src/components/ListingFilters.astro`, `src/pages/places/index.astro`, `src/lib/contributor.ts`,
`src/lib/auth/*`, `src/lib/security.ts`, `src/styles/global.css`). WCAG 2.2 success criteria referenced
inline. Refresh this doc when the search surface, the auth boundary, or the theme token set changes
materially.
