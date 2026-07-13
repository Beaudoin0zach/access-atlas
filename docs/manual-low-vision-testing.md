# Manual low-vision testing — run sheet (desktop)

**Who this is for:** paid community co-designer testers who use screen
magnification, browser zoom, large text, high-contrast or inverted-color
modes — with or without a screen reader alongside. Use **your** setup, at
**your** everyday zoom level and colors; that configuration is the test.

Session logistics, scoring, breaks, and pay terms are identical to the other
sessions — your facilitator runs everything and writes everything down
([facilitator guide](manual-at-testing-facilitator.md)). If a bug blocks a
step, say so and move on.

**What machines already check, so you don't have to:** every page is
automatically tested for horizontal-scroll reflow at 320px (the 400%-zoom
equivalent) and for color-contrast minimums on every code change. This
session is about what those checks can't see: whether the pages are actually
**readable and usable** the way you look at them.

---

## Part 1 — Your everyday view

Browse the home page, both directory lists, and one detail page exactly as
you normally browse.

1. At your normal zoom/magnification, reading a listing top to bottom: does
   anything overlap, get cut off, or disappear?
2. Reading never requires scrolling **sideways** — up and down only.
3. Nothing important lives only in your peripheral vision — messages appear
   near where you're already looking or at the top where you'd check.

---

## Part 2 — Push the zoom

Set browser zoom to 200%, then 400% (your facilitator can help).

1. On a detail page: every trust label ("Community-verified,"
   "Self-reported / awaiting verification," "Disputed — under re-review")
   stays on-screen, readable, and attached to the fact it belongs to — you
   never have to guess which label goes with which fact.
2. Photos scale without covering text; their captions ("Photo from…" /
   "Problem reported — photo from…") stay with their photos.
3. On the "Report your visit" form at 400%: every field label stays visibly
   attached to its field, and the submit button is findable without a hunt.
4. After submitting with an error (leave the yes/no unanswered): can you
   **find** the error message at this zoom level? Tell your facilitator how
   long it took.

---

## Part 3 — The site's own settings vs. your setup

On the Accessibility settings page, with your normal OS/browser
configuration still active:

1. Turn on the site's **High contrast** setting and save. Does it fight or
   cooperate with your own contrast/inversion setup? "It got worse for me"
   is a critical finding.
2. Set **Text size** to Extra large on top of your own zoom. Layout should
   still hold — no overlaps, no clipped text, no sideways scrolling.
3. Turn on **Larger click and tap targets** — controls grow; nothing
   overlaps.
4. If you use Windows High Contrast / forced-colors mode: browse a list and
   a detail page with it on. Trust labels must still be distinguishable and
   focus must still be visible. (Skip if you don't use it — noted as N/A,
   not a gap in your run.)
5. Reset to defaults; confirm everything returns to normal.

---

## Wrap-up

In your own words, to your facilitator:

1. Where did you have to work hardest to read or find something?
2. Did the site's own accessibility settings help you, get in your way, or
   neither?
3. Would you trust this site to tell you whether you can get into a
   building? Why or why not?

Thank you — every failure you find is a bug in the site, never in you.

---

<!-- For editors: the automated halves of this protocol live in
tests/a11y/pages.spec.ts (320px reflow + axe contrast). The site-settings
mechanics are in src/lib/settings.ts and src/pages/settings.astro. -->
