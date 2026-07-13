# Manual keyboard-only testing — run sheet (sighted, desktop)

**Who this is for:** paid community co-designer testers who navigate by
keyboard, switch device, or other alternatives to a mouse — and can see the
screen. This session finds the one failure class a screen-reader session
cannot: places where you can't **see** where you are.

**If you use a switch or another input method:** use it exactly as you
normally do — your normal method IS the test. Anything you can't reach or
can't trigger is a finding, whatever the cause.

Session logistics, scoring, breaks, and pay terms are identical to the
screen-reader sessions — your facilitator runs everything and writes
everything down ([facilitator guide](manual-at-testing-facilitator.md)).
You never fill in a form or edit this document. If a bug blocks a step, say
so and move on — a blocking bug is the best find of the session.

**The mouse stays unplugged for the whole session.**

---

## Part 1 — Can you always see where you are?

This is the heart of the session. At **every single stop** as you move
through pages, ask: *do I know, at a glance, which element is focused?*

1. On any page, press `Tab` once. A "Skip to main content" link should
   **appear** (it's hidden until focused) in the top corner. Activate it —
   the next `Tab` should land you in the main content, past the menu.
2. Keep tabbing through the header: each menu link should show a clearly
   visible outline — on the dark header bar the ring is light, so it stays
   visible against the teal.
3. Tab into the page body: links, buttons, and form fields should each show
   a clearly visible ring on the light background.
4. **The whole-session check:** any time during this script you look at the
   screen and genuinely can't tell where focus is — even for a moment — tell
   your facilitator *where*. Losing sight of focus is a failure even if you
   found it again by pressing Tab.

---

## Part 2 — Order and reachability

Work through the home page, both directory lists (Places and Providers), one
place and one provider detail page, and the Help page.

1. **Focus order follows reading order.** Tabbing should move top-to-bottom,
   left-to-right — never jumping backwards or leaping somewhere surprising.
2. **Everything interactive is reachable.** Every link, button, form field,
   and fold-out question must be reachable by `Tab`/arrows alone. Nothing on
   this site should require hovering a mouse to reveal or reach.
3. **Fold-out questions** (Help page): `Tab` to a question, open it with
   Enter or Space, and the links inside the opened answer are tabbable.
   Close it again with Enter or Space.
4. **Nothing traps you.** You can always Tab out of whatever you're in —
   fields, fold-outs, photo links.

---

## Part 3 — Forms without a mouse

Use the "Report your visit" form (from any detail page) and the "Suggest a
listing" form. Your facilitator gives you test answers — nothing needs to be
true about you.

1. **Radio buttons:** reach the yes/no group with `Tab`, move between the
   two options with arrow keys, select with Space.
2. **Checkboxes:** every checkbox toggles with Space.
3. **Dropdowns** (Settings page): open and change with arrow keys alone.
4. **Error handling keeps you oriented.** Submit the "Suggest a listing"
   form with the name empty. You should be stopped, and focus should land
   **on the name field** — visibly ringed — not at the top of the page and
   not nowhere. You should be able to type immediately.
5. **After any successful submit,** the page that loads starts you at the
   top with the confirmation message near it. Press `Tab` once — focus
   visibly appears. You're never dropped somewhere invisible.

---

## Part 4 — Settings, quickly

On the Accessibility settings page, keyboard only:

1. Change Text size, save, and confirm the ring is still clearly visible at
   the larger text size.
2. Turn on High contrast, save — the focus ring must remain clearly visible
   in the high-contrast look too.
3. Turn on "Larger click and tap targets," save — controls get bigger;
   nothing overlaps or hides.
4. Reset to defaults.

---

## Wrap-up

In your own words, to your facilitator:

1. Where did you most nearly lose track of where you were?
2. Was anything slower or more tiring by keyboard than it should be?
3. If you use a switch or other input method: did anything behave
   differently from the sites you use comfortably?

Thank you — every failure you find is a bug in the site, never in you.

---

<!-- For editors: focus styling this script relies on lives in
src/styles/global.css (the :focus-visible outline block, the header
outline-color override, and .skip-link:focus). If those rules change,
re-check Parts 1 and 4. -->
