# Manual screen-reader testing — run sheet

**Who this is for:** paid community co-designer testers running VoiceOver
(Mac or iPhone/iPad) or NVDA (Windows). You do not need to be an engineer.
You do not need to know how the site is built. You just need to use it the
way you normally use the web, and tell us honestly what worked and what
didn't.

> **This checklist does not replace paid disabled co-designer testing
> (CLAUDE.md §5) — it IS the structured script for those sessions.**
> Automated scanners catch roughly 40% of accessibility problems. The other
> 60% — confusing announcements, wrong reading order, things that "pass" but
> make no sense — can only be found by a person using assistive technology
> for real. That person is you, and your time is paid.

---

## Before you start

Fill this in once per session:

| | |
|---|---|
| Your name or tester code | |
| Date | |
| Screen reader + version | (e.g., NVDA 2025.1, VoiceOver on macOS 15, VoiceOver on iOS 18) |
| Browser + version | |
| Site address you tested | (your facilitator gives you this — usually a test address, not the live site) |

**Recommended pairings** (test with what you actually use day to day — that
matters more than this list):

- NVDA with Firefox or Chrome on Windows
- VoiceOver with Safari on a Mac
- VoiceOver with Safari on an iPhone or iPad

### Quick command reminders

You likely know these already — this is just for reference.

**NVDA (Windows):** `H` = next heading · `F` = next form field · `B` = next
button · `K` = next link · Arrow keys = read line by line · `Tab` = next
focusable thing · `NVDA+F7` = list of headings/links/landmarks · `NVDA+T` =
read the page title.

**VoiceOver (Mac):** `VO` means Control+Option (or Caps Lock). `VO+Right
Arrow` = next item · `VO+U` = rotor (headings, links, form controls) ·
`Tab` = next focusable thing · `VO+F2` = read the window/page title.

**VoiceOver (iPhone/iPad):** swipe right = next item · double-tap =
activate · two-finger twist = rotor · pick "Headings" in the rotor and swipe
down to jump by heading.

### How to record results

Every check below has a checkbox:

- **Tick the box** if it passed.
- **Leave it empty and write a note** if it failed. The most useful note is:
  *what you did, the exact words your screen reader said, and what you
  expected instead.* "It said 'button' with no name" is gold. "It felt off"
  is also fine — say so, we will dig in together.

The expected announcements below are written like "you should hear
**something like** …". Every screen reader phrases things a bit differently.
The exact wording doesn't matter. What matters: **the meaning is there, and
nothing important is missing.**

---

## Part 0 — Checks that apply on EVERY page

Run these on the first page you visit, then spot-check them as you go. If
one fails anywhere, note which page.

1. **Page title.** Ask your screen reader for the window/page title
   (`NVDA+T` / `VO+F2`). It should name the page and end with
   "— Access Atlas" (for example, "Places — Access Atlas").
   - [ ] Every page I visited had a title that told me where I was.

2. **Skip link.** Reload the page, then press `Tab` once. The very first
   thing you reach should be a link that says **"Skip to main content."**
   Press Enter — reading should continue at the page's main content, not
   back at the top menu.
   - [ ] The skip link is the first Tab stop and it works.

3. **Landmarks.** Open your landmark list (NVDA elements list, or the
   VoiceOver rotor). You should find: a **banner/header**, a navigation
   named **"Primary"**, a **main** region, and a **footer/content info**.
   - [ ] All four landmarks are there and the navigation has a name.

4. **One main heading.** Each page has exactly one level-1 heading, and it
   matches what the page is about.
   - [ ] Every page I visited had one clear level-1 heading.

5. **Keyboard only, no traps.** Put the mouse away for the whole session.
   You should be able to reach every link, button, and form field with the
   keyboard, and never get stuck somewhere `Tab` or the arrow keys can't
   leave.
   - [ ] I completed this whole script without the mouse and never got stuck.

6. **The main menu.** In the header navigation you should find these links,
   each announced as a link with a clear name: **Places, Providers, Suggest
   a listing, Help, Accessibility, Privacy.**
   - [ ] All six menu links are announced clearly.

---

## Part 1 — Home page (`/`)

**Get there:** open the site's address, or activate "Access Atlas — home" in
the header.

1. Jump by headings. You should hear one level-1 heading, **something like**
   "Accessible places and providers, validated by the community."
   - [ ] The main heading is announced.

2. After the intro text you should reach two links: **"Browse places"** and
   **"Browse providers."** Both should be announced as links (they look like
   buttons on screen — as long as they're announced with a clear name,
   that's a pass).
   - [ ] Both links are reachable and clearly named.

3. Read the box that starts **"How to read our labels."** It should read as
   normal text, in a sensible order, explaining self-reported vs.
   community-verified.
   - [ ] The labels explanation reads in a sensible order and makes sense.

4. **Plain-language check (your judgment):** after hearing this page once,
   could you explain to a friend what this site is for?
   - [ ] Yes — the purpose was clear from listening alone.

---

## Part 2 — Places list (`/places/`)

**Get there:** "Browse places" on the home page, or "Places" in the menu.

1. The level-1 heading is **"Accessible places."** Right after it, a
   sentence tells you **how many places are listed** — you should not have
   to count them yourself.
   - [ ] The count is announced before the list.

2. You should find a link **"+ Suggest a place"** before the list.
   - [ ] The suggest link is there and clearly named.

3. The places are a **list**. Your screen reader should announce it as a
   list and say how many items it has. Each place is a level-3 heading with
   a link — so jumping by headings should hop place to place.
   - [ ] The list is announced as a list, and heading-jumping moves between
     places.

4. Some places carry tags read as plain text, **something like**
   "Disabled-owned (self-attested)" or "Disability-literate (self-attested)."
   These must be spoken, not just shown as a colored chip.
   - [ ] Any tags on a place are read out loud.

---

## Part 3 — A place's detail page (`/places/…`)

**Get there:** from the places list, activate any place's name link.
Pick one that has photos if your facilitator can point you to one.

1. First link on the page: **"← All places"** (a way back). Then the place's
   name as the level-1 heading.
   - [ ] Back link and main heading are announced.

2. Find the **"Accessibility"** heading. Under it, a sentence says each item
   is validated on its own, never rolled into a star rating. Then a list of
   accessibility facts.
   - [ ] The accessibility section is reachable by heading and reads in
     order.

3. **Each fact reads as a complete thought.** For each item you should hear,
   in order: the fact's name (like "Step-free entrance"), then its trust
   label **in words** (like "self-reported / awaiting verification" or
   "community-verified"), then a short description of what that label means,
   and — when it exists — a "Last confirmed:" date. You must never have to
   guess trust from a color or symbol alone.
   - [ ] Every fact's trust label and its meaning are spoken in words.
   - [ ] "Last confirmed" dates are read where present.

4. **Evidence photos (new — please test carefully).** Facts that have photo
   evidence show a photo list announced **something like** "Photo evidence
   for 'Step-free entrance', list."
   - [ ] The photo list announces which fact it belongs to.

   For each photo:
   - The image's description is read out. It should be the description a
     visitor wrote — a real sentence about what the photo shows (like "the
     front entrance, one step up, no ramp"). If nobody wrote one, you should
     hear the honest fallback: **"Evidence photo (no description was
     provided)"** — never a filename, never silence.
     - [ ] Every photo has a spoken description or the honest fallback.
   - The caption after the image says **"Photo from"** plus a date — or
     **"Problem reported — photo from"** plus a date when the photo shows
     something wrong. That difference is safety information: you must be
     able to hear it, not just see red styling.
     - [ ] "Problem reported" captions are clearly spoken where they exist.
   - Each photo has a **"Full size"** link. It should be reachable by
     keyboard and announced as a link.
     - [ ] Full-size links are reachable and named.

5. Each fact ends with a link **"Report your visit for '…'"** naming the
   specific fact — so out of context (in a links list) you still know which
   fact it's for.
   - [ ] Report links name their fact.

6. The closing note ("Accessibility facts change — ramps break…") reads as
   plain text.
   - [ ] The staleness note is read.

---

## Part 4 — Report your visit (`/contribute/confirm/…`)

**Get there:** on a place's page, activate any **"Report your visit for
'…'"** link.

This form is the safety-critical heart of the site. Take your time here.

1. The page starts with a link back to the place, then the level-1 heading
   **"Report your visit,"** then a sentence naming the place and the exact
   claim you're reporting on.
   - [ ] I knew which place and which claim I was reporting on from
     listening alone.

2. You may hear a sign-in notice (**something like** "To report a visit,
   please sign in to contribute. Browsing stays account-free."). If so, it
   should read as a normal message, and the sign-in link should work by
   keyboard. Your facilitator will tell you whether to sign in or test the
   form signed out.
   - [ ] Any sign-in message was announced and its link worked.

3. **The yes/no question (radio buttons).** Move into the form. When you
   reach the first radio button you should hear the **question itself**
   (like "Does the entrance have zero steps?") as the group's name, then the
   option **"Yes — my visit confirms this,"** announced as a radio button,
   marked required. The second option is **"No — this was NOT true on my
   visit."** Arrow keys should move between the two.
   - [ ] The question is announced when I reach the radio buttons.
   - [ ] Both options are announced as radio buttons and arrows move
     between them.
   - [ ] The note that a single "no" freezes the claim is read after the
     options.

4. **Date of your visit** — announced as an optional date field with its
   label.
   - [ ] Labeled and reachable.

5. **Photo field.** The label itself tells you whether a photo is required
   for this claim ("Photo evidence — required to confirm this attribute") or
   optional. Right after the field you should hear: **"Location and device
   data are removed from your photo before it is stored."**
   - [ ] The label says whether a photo is required.
   - [ ] The privacy note about location data is announced with the field.

6. **Photo description field (required if you attach a photo).** Its label:
   **"Describe what your photo shows — required if you attach a photo."**
   With it you should hear the example hint ("For example: 'the front
   entrance, one step up, no ramp.' Your description is read aloud to blind
   and low-vision users — it's part of the evidence.").
   - [ ] Label and example hint are both announced.

7. **Access-experience checkboxes.** A group whose name says **something
   like** "Optional: which access experience are you speaking from? Never
   shown tied to you — used only to weight your report." Inside, five
   checkboxes: wheelchair or mobility device / blind or low vision / Deaf or
   hard of hearing / cognitive or learning access needs / neurodivergent.
   - [ ] The group's purpose (optional, never shown tied to you) is
     announced before or with the checkboxes.
   - [ ] All five checkboxes have clear spoken labels and toggle with Space.
   - **Your judgment:** does this group feel safe and optional — not like
     the site is fishing for your diagnosis?
   - [ ] It felt optional and safe.

8. The notes box and the display-name field are labeled and optional, and
   the display-name label says it's **not your real name**.
   - [ ] Both labeled; the pseudonym hint is spoken.

9. **Error messages (do these on purpose):**
   - Submit **without choosing yes or no.** You should be stopped and told —
     either by your browser on the field itself, or by a page message spoken
     **automatically** (without you hunting for it): "Please choose whether
     your visit confirmed the claim or not."
     - [ ] The missing-answer error was announced automatically and told me
       what to fix.
   - Choose **Yes**, attach any photo, leave the description empty, submit.
     You should automatically hear **something like**: "Please describe what
     your photo shows — the description is what makes it evidence for blind
     and low-vision users."
     - [ ] The missing-description error was announced automatically.
   - If the claim requires a photo: choose **Yes** with no photo and submit.
     You should hear: "A photo is required to confirm this attribute. (You
     can dissent without one.)"
     - [ ] The photo-required error was announced automatically (skip if
       your claim doesn't require a photo).

10. **Success.** Fill the form honestly (your facilitator will say what to
    enter on a test site) and submit. The page should automatically announce
    **something like**: "Thank you — your visit was recorded. It counts
    toward this claim once enough independent visits agree." Submitting the
    same claim again should say you've **already reported** it and each
    person counts once.
    - [ ] The thank-you message was announced automatically.
    - [ ] The already-reported message was announced on a second try.

---

## Part 5 — Suggest a listing (`/contribute/submit/`)

**Get there:** "Suggest a listing" in the menu, or "+ Suggest a place" on
the places list.

1. The heading tells you what you're adding ("Suggest a place"), and right
   after it a link offers the other kind: **"Add a provider instead."**
   Activate it — the heading should now say "Suggest a provider," and a new
   group of checkboxes about provider competence should appear. Then switch
   back.
   - [ ] Switching between place and provider is a plain link, works by
     keyboard, and the page tells me which one I'm on.

2. Early on, the page says new listings start as **"self-reported / awaiting
   verification."**
   - [ ] That honesty note is read before the form.

3. **Name field.** Its label is "Name" and it is announced as **required**.
   - [ ] Announced as required.

4. Submit with the name **empty**. You should be stopped at the name field
   and told it must be filled in (browsers usually announce "invalid entry"
   and move you there). If a page message appears instead, it should say
   "Please give the place or provider a name" and your focus should land on
   the name field.
   - [ ] The empty-name error put me on the name field and told me what to
     fix.

5. The address, ownership, and accessibility-features groups each announce
   their purpose when you enter them — "Where is it? (Buffalo / Erie County
   first — optional)", "Ownership & leadership (self-attested — no proof
   required)", "Which accessibility features did you observe? (optional;
   self-reported — others will confirm from their own visits)". Every
   checkbox inside has a clear spoken label.
   - [ ] Each group announces its purpose.
   - [ ] Every checkbox is clearly labeled and toggles with Space.

6. Submit a complete test listing (facilitator's go-ahead). You should land
   on the new listing's page and **automatically** hear: "Thanks — your
   listing was added. It starts as 'self-reported / awaiting verification'
   until community visits confirm it."
   - [ ] The success message was announced on the new listing's page.

---

## Part 6 — Accessibility settings (`/settings/`)

**Get there:** "Accessibility" in the menu.

This page must not just *announce* well — every setting must actually **take
effect and stick**.

1. Before the form, a note says settings are stored **on this device only**,
   with no account and no tracking.
   - [ ] The privacy note is read before the form.

2. The form has three groups — **Text**, **Colour & motion**, **Pointer &
   touch** — each announcing its name. Inside: three labeled dropdowns
   (Text size, Line spacing, Font) and three labeled checkboxes (High
   contrast, Reduce motion, Larger click and tap targets). The Font dropdown
   also carries a hint explaining "Readable" vs "OpenDyslexic."
   - [ ] All six controls are labeled and operable with the keyboard alone
     (arrows change dropdowns, Space toggles checkboxes).
   - [ ] The font hint is announced with the Font dropdown.

3. Two buttons: **"Save settings"** and **"Reset to defaults."**
   - [ ] Both announced as buttons with those names.

4. **Does each setting work? Test one at a time:**
   - Set **Text size** to "Extra large (150%)" and save. You should
     automatically hear: "Your accessibility settings were saved. They're
     applied below." Sighted check (facilitator or low-vision tester): the
     text is visibly bigger.
     - [ ] Save announced; text size actually changed.
   - **It persists:** go to the home page, then come back to Settings. The
     text should still be large, and the Text size dropdown should announce
     "Extra large (150%)" as the current choice.
     - [ ] The setting survived leaving and returning.
   - Turn on **High contrast**, save, and confirm the page looks/reads with
     stronger contrast (sighted check).
     - [ ] High contrast took effect after saving.
   - Turn on **Reduce motion**, save. (Effect is subtle on this site —
     confirm the save is announced and the checkbox stays checked when you
     return.)
     - [ ] Reduce motion saved and persisted.
   - Set **Font** to OpenDyslexic, save, sighted check that the typeface
     changed; return and confirm the dropdown still says OpenDyslexic.
     - [ ] Font change took effect and persisted.
   - Turn on **Larger click and tap targets**, save. On a touch device,
     links and buttons should be comfortably bigger targets.
     - [ ] Larger targets saved (and felt bigger on touch, if tested).
   - Press **"Reset to defaults."** You should hear: "Your accessibility
     settings were reset to the defaults," and the page returns to normal
     size.
     - [ ] Reset announced and everything returned to defaults.

---

## Part 7 — Your data (`/account/`)

**Get there:** the **"Your data"** link in the footer.

What you find depends on whether you're signed in and have contributed.
Test the state your facilitator sets up; note which one you saw.

1. The level-1 heading is **"Your data."** The intro says browsing needs no
   account and, for most visitors, the site holds nothing at all.
   - [ ] Heading and intro are announced and understandable.

2. **If you're not signed in:** you should hear a message like "To manage
   your data, please sign in — we can only show your data to you," with a
   working sign-in link. (Or, if contributions aren't open: a plain message
   saying so.)
   - [ ] The signed-out message was announced and made sense.

3. **If you're signed in and have contributed:** under "What we hold about
   you," a short list reads your display name, how many visit reports, and
   how many listings you suggested — followed by: "That's the whole list. We
   never hold your specific disability or diagnosis — we never ask for it."
   - [ ] The list reads completely and the never-ask promise is spoken.

4. **"Download my data (JSON)"** is a button. Activating it downloads one
   file immediately — no form, no waiting.
   - [ ] The download button is announced and produces a file.

5. A link **"Delete my data…"** leads to a separate confirmation page (next
   part). The text before it warns it cannot be undone and that you'll be
   asked to confirm first.
   - [ ] The delete link and its warning are announced before anything
     destructive can happen.

6. If a **Sign out** button is present, it's announced as a button, and its
   explanation ("ends this session everywhere") is read.
   - [ ] Sign out is a clearly named button.

---

## Part 8 — Delete your data (`/account/delete/`)

**Get there:** "Delete my data…" on the Your data page.
**Only do this with test data your facilitator says is safe to delete.**

This is the one destructive action on the site. The protection is a typed
word — not a pop-up — precisely so it works for everyone. Please test that
it really protects.

1. Before any button, the page reads two plain sections: **"What will be
   deleted"** (your reports, photos, tags, display name, account) and
   **"What stays"** (listings you suggested, with your name detached), then
   a clear warning: **"This cannot be undone,"** with a pointer to
   downloading a copy instead.
   - [ ] I heard exactly what would be deleted and what would stay,
     *before* reaching the delete button.

2. **The confirmation field.** Its label says: "To confirm, type the word
   **delete**" and is announced as **required**. With it you should hear the
   explanation: "Typing the word is asked so a stray click or key press can
   never erase your data. Capital letters are fine."
   - [ ] The label, the required state, and the why-we-ask note are all
     spoken.

3. The button is named **"Permanently delete my data"** — no vague "OK" or
   "Submit."
   - [ ] The button name states the consequence.

4. A safe way out — the link **"Cancel and keep my data"** — is present and
   reachable by keyboard.
   - [ ] The cancel link is there and works.

5. **The guard actually guards.** Type the **wrong** word (like "yes") and
   submit. Nothing should be deleted, and you should automatically hear:
   "Please type the word 'delete' in the confirmation box — nothing was
   deleted." Leaving it empty should also stop you (the browser will insist
   on the field).
   - [ ] Wrong word: stopped, told why, nothing deleted.
   - [ ] Empty: stopped at the field.

6. **The real deletion** (test data only!). Type **delete** — try it with
   capital letters; that must also work — and submit. You should land back
   on Your data and automatically hear: "Your data has been deleted.
   Listings you suggested stay in the directory, with your name detached."
   - [ ] Deletion worked, capitals were accepted, and the confirmation was
     announced automatically.

---

## Part 9 — Help & plain words (`/about/help/`)

**Get there:** "Help" in the menu.

1. The glossary under **"Words we use"** reads as term-then-meaning pairs,
   in order, with nothing skipped.
   - [ ] Every term and its meaning are read as a pair.

2. **The fold-out questions under "Common questions."** Each question (like
   "Do I need an account to look around?") should be announced as something
   you can open — typically "summary" or "disclosure triangle" or a button —
   with a **collapsed/expanded** state.
   - Press Enter or Space on a question: it should announce it's now
     **expanded**, and reading onward gives the answer.
   - Press again: **collapsed**, and the answer is gone from the reading
     order.
   - [ ] Each question announces open/closed state and toggles with
     Enter/Space.
   - [ ] Answers are only in the reading order while open.
   - [ ] All six questions behave the same way.

3. Links inside the answers (privacy policy, Accessibility settings, Your
   data) are reachable by keyboard once the answer is open.
   - [ ] Links inside opened answers work by keyboard.

4. **Plain-language check (your judgment):** the whole page promises "short
   sentences, no jargon." Did it deliver? Flag any sentence you had to
   re-read.
   - [ ] The page was genuinely plain to me. (Note any sentence that
     wasn't.)

---

## Wrap-up

Three questions in your own words — these are as important as every
checkbox above:

1. What was the most confusing or tiring moment of the session?
2. Was anything announced in a way that felt dishonest, patronizing, or
   unsafe?
3. Would you trust this site to tell you whether you can get into a
   building? Why or why not?

Thank you. Your report — including every failure — directly changes what
ships. Nothing in this script is a test of *you*; every failure is a bug in
*the site*.
