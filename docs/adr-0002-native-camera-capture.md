# ADR 0002 — Native camera capture on the confirm flow (a scoped script)

Status: **Accepted** (2026-07-23). To be raised as a **BAS ADR** (§15) because it
narrows a browsing/contribute non-negotiable. Follows the precedent of
[ADR 0001](adr-0001-nearby-geolocation.md); scope in
[ios-camera-evidence-scope.md](ios-camera-evidence-scope.md).

## Context

The surface is **zero-JavaScript** by design: `script-src 'none'` in the CSP
(§2/§5/§14, `src/lib/security.ts`). ADR 0001 opened one narrow exception — a
self-hosted enhancement on the two list index routes.

The iOS TestFlight track (§13) needs to clear **App Review Guideline 4.2
(minimum functionality)** for *external* beta: a wrapper that is "just a website"
is rejected. The confirm flow already captures evidence with
`<input type="file" accept="image/*">`, but that opens the camera **in Mobile
Safari too**, so it is not a native differentiator. Native camera access
(`@capacitor/camera`, `Camera.getPhoto()`) is — and it requires JavaScript, which
conflicts with the zero-JS default on the confirm route. Per §2, the conflict is
decided explicitly rather than worked around.

## Decision

Add **one** self-hosted, dependency-free script — `public/confirm-camera.js` —
loaded **only** on the confirm route (`/contribute/confirm/<claimId>`), as a
**progressive enhancement**.

Guardrails that keep this the *minimal* departure:

1. **Native-only, no-ops on web.** The script returns immediately unless
   `window.Capacitor?.isNativePlatform()`. On the web (Capacitor absent) it adds
   nothing — the `<input type="file">` remains the baseline and the confirm form
   works with no JS. It changes behaviour only inside the Capacitor iOS app.
2. **No backend change; same evidence pipeline.** The captured image is dropped
   into the existing `#photo` field, so it takes the identical POST -> sharp
   (EXIF/GPS strip) -> thumbnail -> `evidence_photos` path
   (`src/pages/api/confirmations.ts`). Alt text stays **required** (§4/§6), and
   the script sends focus to the alt field after capture.
3. **The CSP stays `default-src 'none'` with no `connect-src`.** Even on this
   route the script cannot make a network request. The camera plugin talks to
   native over the Capacitor bridge (`window.Capacitor.Plugins`), not the network,
   and the base64 -> `Blob` conversion is local (`atob`, no `fetch`). Nothing
   leaves the device by network (§6). `script-src` relaxes to `'self'` on this
   route only; no inline script anywhere.
4. **Contribute, not browse.** This is a contribution route (already gated on
   contributions being open), not part of the zero-JS *browsing* guarantee the
   list-detail and About pages keep absolutely.
5. **No bundled dependency in the web build.** The script calls the plugin via
   the global bridge, so `@capacitor/camera` is a native pod only — the web
   lockfile / zero-build model is unchanged.

## Consequences

- Web visitors to the confirm route now download one tiny script (like `nearby.js`
  on the list pages) and that route serves `script-src 'self'`. Accepted for a
  contribute route; browsing routes are untouched.
- The a11y suite asserts the confirm route ships exactly one self-hosted script
  and no inline script, locking the contract (`tests/a11y/pages.spec.ts`).
- **Pending on-device proof:** that the plugin is reachable via the global bridge
  without bundling. Fallback if not: a one-file Astro client entry importing the
  plugin — still one self-hosted script. Native pod, Info.plist usage strings,
  and the VoiceOver capture round-trip are build-machine steps (see the scope).
