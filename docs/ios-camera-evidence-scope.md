# Scope — native camera evidence capture (`@capacitor/camera`)

Status: **in progress** (repo-side pieces landing; native + on-device steps pending a Mac).
Related: CLAUDE.md §13 (TestFlight track), [ios-testflight.md](ios-testflight.md),
[adr-0002-native-camera-capture.md](adr-0002-native-camera-capture.md),
[adr-0001-nearby-geolocation.md](adr-0001-nearby-geolocation.md) (the pattern this mirrors).

## Why

External TestFlight (>100 testers, public beta) requires passing **App Review
Guideline 4.2 (minimum functionality)** — a wrapper that is "just a website" is
rejected. Internal TestFlight (≤100) does not need this.

Today the confirm flow captures evidence with a plain
`<input type="file" name="photo" accept="image/*">`
([`src/pages/contribute/confirm/[claimId].astro`](../src/pages/contribute/confirm/%5BclaimId%5D.astro))
posting multipart to [`src/pages/api/confirmations.ts`](../src/pages/api/confirmations.ts).
On iOS that file input already opens the camera **in Mobile Safari too**, so it is
**not** a native differentiator. `@capacitor/camera`'s `Camera.getPhoto()` is
native camera access the web can't replicate — the value-add that clears 4.2, and
one tied directly to the app's purpose (first-person accessibility evidence, §4).

## Architecture — progressive enhancement, native-only activation

The contribute pages are served `script-src 'none'` (the zero-JS posture,
[`src/lib/security.ts`](../src/lib/security.ts)). Camera needs JavaScript. The
resolution mirrors the one existing sanctioned enhancement, `nearby.js`:

- A single self-hosted vanilla script (`public/confirm-camera.js`) that
  **no-ops unless `window.Capacitor?.isNativePlatform()`**. In the iOS app it adds
  a "Take photo" button; on web (Capacitor absent) the file input stays the
  baseline, byte-for-byte unchanged.
- It calls **`window.Capacitor.Plugins.Camera.getPhoto(...)` via the global
  bridge** (the native side auto-registers the plugin once the pod is installed),
  so we do **not** bundle the npm package — the zero-build, self-hosted-script
  model is intact.
- Result comes back as **base64**, is turned into a `Blob`/`File` with `atob`
  (no `fetch`), and is injected into the existing `#photo` field via
  `DataTransfer`. The existing POST → sharp (EXIF/GPS strip) → thumbnail →
  `evidence_photos` view path is **unchanged; no backend change**.

## Constraints honored

- **§5 zero-JS browsing** is untouched — this is a *contribute* route, and the
  file-input baseline still works with JS off (true progressive enhancement).
- **§6 privacy** — EXIF/GPS is already stripped server-side by sharp; the native
  path adds no location metadata; alt text stays **required**.
- **§4 evidence** — same evidence pipeline, same public `evidence_photos` view.
- The confirm flow is already gated on contributions being open; camera only
  matters there.

## Work items

| # | Item | Where | Side |
|---|------|-------|------|
| 1 | `npm i @capacitor/camera` | `package.json` | repo |
| 2 | `npx cap sync ios`; `NSCameraUsageDescription` + `NSPhotoLibraryUsageDescription` in Info.plist; privacy nutrition label | `ios/` (gitignored) | **Mac** |
| 3 | `public/confirm-camera.js` — native-gated "Take photo" → base64 → `File` into `#photo` | repo | repo |
| 4 | CSP: add `/contribute/confirm/` to the script-enhanced routes + **ADR-0002** | `src/lib/security.ts`, `docs/adr-0002-*` | repo |
| 5 | a11y test: confirm route ships exactly one self-hosted script, no inline | `tests/a11y/pages.spec.ts` | repo |
| 6 | On-device verify: VoiceOver + capture round-trip to the `evidence_photos` view | device | **Mac + device** |

Items 3–5 (repo-side) land first and need no Mac. Items 1–2, 6 need a build machine.

## Biggest unknown (de-risk on device first)

That the plugin is reachable via `window.Capacitor.Plugins.Camera` **without
bundling** the npm wrapper. If a real device shows it isn't, the fallback is a
tiny Astro-built client entry that imports `@capacitor/camera` — still one
self-hosted script, one extra build step. Everything else in this scope holds.

## Not in scope here

- Adding `@capacitor/camera` to `package.json` (item 1) and the native Info.plist
  strings (item 2) land with the build-machine work, not the repo-side PR.
- Whether to also offer native photo-library pick (the plugin supports it) — a
  small follow-on once the camera path is proven.
