/*
 * confirm-camera.js — native camera capture for the confirm-flow photo field.
 *
 * The SECOND (and only other) script the site ships, and like nearby.js it is a
 * PROGRESSIVE ENHANCEMENT that runs on exactly one kind of route
 * (/contribute/confirm/<claimId>). The confirm form works fully without it: the
 * <input type="file" accept="image/*"> is the baseline on web and JS-off.
 *
 * NATIVE-ONLY: this no-ops entirely unless it is running inside the Capacitor
 * iOS app (window.Capacitor.isNativePlatform()). On the web it adds nothing, so
 * the web experience is byte-for-byte the server-rendered form. Its whole reason
 * to exist is App Review Guideline 4.2 (a wrapper needs native capability the
 * web lacks); see docs/ios-camera-evidence-scope.md + docs/adr-0002-native-camera-capture.md.
 *
 * PRIVACY (§6): the captured image is handed straight to the SAME form field the
 * file input uses, so it takes the identical POST -> sharp (EXIF/GPS strip) ->
 * thumbnail path (src/pages/api/confirmations.ts). The base64 -> Blob conversion
 * is local (atob, no fetch); the plugin talks to native over the Capacitor
 * bridge, not the network. The page CSP stays default-src 'none' with no
 * connect-src, so this script cannot make a network request.
 */
(function () {
  'use strict';

  var cap = window.Capacitor;
  // No Capacitor, or running in a plain browser -> leave the file input alone.
  if (!cap || typeof cap.isNativePlatform !== 'function' || !cap.isNativePlatform()) return;
  var Camera = cap.Plugins && cap.Plugins.Camera;
  if (!Camera || typeof Camera.getPhoto !== 'function') return;

  var input = document.getElementById('photo');
  if (!input) return;

  // --- UI: a "Take photo" button + a polite status line, next to the input ----
  var btn = document.createElement('button');
  btn.type = 'button'; // never submit the form
  btn.className = 'btn';
  btn.textContent = 'Take a photo with the camera';

  var status = document.createElement('p');
  status.className = 'attr-desc';
  status.setAttribute('role', 'status');
  status.setAttribute('aria-live', 'polite');
  status.setAttribute('aria-atomic', 'true');

  // Placed right after the file input so the two capture paths sit together and
  // the tab order stays: file input -> take-photo button -> status.
  input.parentNode.insertBefore(btn, input.nextSibling);
  input.parentNode.insertBefore(status, btn.nextSibling);

  function base64ToFile(base64, format) {
    var type = 'image/' + (format || 'jpeg');
    var bytes = atob(base64);
    var buf = new Uint8Array(bytes.length);
    for (var i = 0; i < bytes.length; i++) buf[i] = bytes.charCodeAt(i);
    return new File([buf], 'evidence.' + (format || 'jpg'), { type: type });
  }

  function attachToInput(file) {
    // DataTransfer is how you set an <input type=file>'s files programmatically;
    // supported in WKWebView. Dispatch 'change' so any listeners + native
    // validation see the new file, and so the field reflects it.
    var dt = new DataTransfer();
    dt.items.add(file);
    input.files = dt.files;
    input.dispatchEvent(new Event('change', { bubbles: true }));
  }

  btn.addEventListener('click', function () {
    btn.disabled = true;
    status.textContent = 'Opening the camera…';
    Camera.getPhoto({
      quality: 80,
      allowEditing: false,
      resultType: 'base64', // CameraResultType.Base64 — no file URL to fetch
      source: 'CAMERA', // CameraSource.Camera
      saveToGallery: false // don't silently write to the user's library (§6)
    }).then(function (photo) {
      if (!photo || !photo.base64String) {
        status.textContent = 'No photo was captured. You can try again or choose a file.';
        btn.disabled = false;
        return;
      }
      attachToInput(base64ToFile(photo.base64String, photo.format));
      status.textContent = 'Photo captured. Now describe what it shows in the field below — that description is required.';
      btn.disabled = false;
      // Alt text is required whenever a photo is attached; send focus there so
      // the next step is obvious to a screen-reader user (§5).
      var alt = document.getElementById('photo_alt');
      if (alt) alt.focus();
    }).catch(function () {
      // getPhoto rejects on user-cancel too — treat both the same, quietly.
      status.textContent = 'No photo added. You can take one, or choose a file instead.';
      btn.disabled = false;
    });
  });
})();
