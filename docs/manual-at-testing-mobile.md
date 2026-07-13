# Manual screen-reader testing — mobile VoiceOver delta (iPhone/iPad)

> **DRAFT — not yet validated on a real device.** Nobody has walked this
> script on iOS hardware yet. Before it is used in a paid tester session, a
> facilitator must dry-run it end to end on an iPhone and fix what doesn't
> hold — the same rule we applied to the desktop sheet. Until then it is a
> planning document, honestly labeled.

**Who this is for:** paid community co-designer testers using VoiceOver on an
iPhone or iPad, with Safari.

**How this document works:** it is a **delta**, not a full script. The pages
to visit, the content to expect, and every "[exact wording matters]" label
are identical to the desktop run sheet
([`manual-at-testing.md`](manual-at-testing.md)) — run its Parts 2 through 11
in order. This document replaces only the **mechanics** (Part 1 and the
"how") and adds the checks that exist only on touch. Logistics and scoring
are unchanged ([facilitator guide](manual-at-testing-facilitator.md)).

---

## How you'll move (instead of the desktop keys)

- **Next / previous item:** swipe right / left.
- **Activate:** double-tap.
- **Rotor:** two-finger twist; pick "Headings" and swipe down/up to jump by
  heading, "Links" or "Form Controls" likewise.
- **Read from here:** two-finger swipe down.
- Wherever the desktop sheet says "press Tab," read: **swipe right**.
  Wherever it says "jump by headings," read: **rotor → Headings → swipe
  down**. Wherever it says "press Enter or Space," read: **double-tap**.

## Part 1 (mobile) — Checks that carry through the whole session

Replaces desktop Part 1:

1. **The skip link.** The first swipe on a freshly loaded page should reach
   "Skip to main content." Double-tap — reading should continue at the main
   content, past the menu.
2. **Nothing is unreachable or sticky.** Every link, button, and form field
   is reachable by swiping alone, and swiping never gets stuck cycling
   inside one area of the page.
3. **The main menu makes sense** — six clearly named links (Places,
   Providers, Suggest a listing, Help, Accessibility, Privacy) and "Your
   data" in the footer.

## Form mechanics (for desktop Parts 5–7)

- **Radio buttons:** swipe to each option and double-tap to select — you
  should hear the question as the group's purpose and each option's
  selected/not-selected state.
- **Checkboxes:** double-tap toggles; the checked state is announced.
- **The date field and dropdowns** open iOS pickers: they must be operable
  with rotor/swipe, and closing the picker must return you where you were.
  *(This is the step most likely to differ from desktop — take notes.)*
- **Photo field (Part 5):** double-tapping should offer the iOS
  photo/camera options. Attach any photo from the test device.

## Mobile-only checks (run after desktop Part 7's settings work)

1. **Pinch zoom is never blocked.** Pinch-zoom into a detail page — the page
   must zoom. A site that disables pinch zoom fails.
2. **Larger targets setting, on touch.** Turn on "Larger click and tap
   targets" and save: links and buttons should be comfortably tappable
   without hitting neighbors — this setting exists *for* touch; judge it
   on touch.
3. **Both orientations.** Rotate to landscape on a list page and a form:
   nothing disappears, reading order stays sensible.
4. **The photo "Full size" link** opens the image; you can get back with
   the browser back control without losing your place in the list.

## Wrap-up

Same three questions as the desktop sheet, plus one:

4. Compared with the sites you normally use on this phone, was this easier,
   harder, or the same? Where?

---

<!-- For editors: keep this a DELTA against manual-at-testing.md — do not
copy content checks into it, or the two will drift. When the Capacitor/
TestFlight build exists (docs/ios-testflight.md), a session should also run
inside the wrapped app, where the same web content is mediated by WKWebView —
add an "in-app" column to the results at that point. -->
