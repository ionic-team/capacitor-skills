# Native Build Verification (Phase 6)

API parity (Phase 5) and the TypeScript build are **static** checks — they do
not prove the generated native code compiles, links, or merges its manifest.
This phase compiles each generated plugin inside a **consuming app**, per
platform, and fixes any failures before the plugins are declared build-ready.

> Build verification ≠ device verification. A green build means the code
> compiles and packages; it does **not** mean the feature behaves correctly at
> runtime. Always record outstanding device-verification work in the summary.

> **The consuming apps are persisted, not throwaway.** Write them to
> `app-{stack}-{plugin}/` (the established repo
> convention), one per stack, and leave them in place. The same app is reused
> for the device pass, so it must survive the session — do **not** scaffold them
> in `/tmp` or delete them once the build is green.

---

## What to build

Each plugin is verified in its own minimal Capacitor app (a Cordova plugin is
consumed through Capacitor's Cordova-compatibility layer):

| Plugin | Consuming app | Plugin dependency |
| --- | --- | --- |
| `capacitor-{plugin}` | `app-capacitor-{plugin}` | `file:../../capacitor-{plugin}` (npm name) |
| `cordova-outsystems-{plugin}` | `app-cordova-{plugin}` | `file:../../cordova-outsystems-{plugin}` (cordova id `com.outsystems.plugins.{plugin}`) |

Generate the plugin's `dist/` first (`npm run build` in the Capacitor plugin) so
the `file:` dependency resolves.

---

## Per-app scaffold

Minimal app (no framework needed — plain `www/`). Both stacks use a **Capacitor**
app — `app-cordova-{plugin}` is a Capacitor app that consumes the Cordova plugin
through Capacitor's Cordova-compatibility layer, **not** a `cordova create`
project:

```
app-{stack}-{plugin}/
├── package.json            # @capacitor/{core,cli,ios,android} + the local plugin
├── capacitor.config.json   # { appId, appName, webDir: "www" }
└── www/index.html          # REQUIRED testable UI: one button per method + result panel
```

The build proves the native code **compiles**; the device pass proves it
**behaves**. The consuming app is the vehicle for both, so its `www/index.html`
is **never** a bare stub — it must ship a minimal but real UI that lets a human
exercise every method on a device. Generate it from the agreed API spec at the
same time as the rest of the scaffold (see "`www/index.html` template" below).

`package.json` dependencies:

```jsonc
{
  "devDependencies": { "@capacitor/cli": "^8.0.0" },
  "dependencies": {
    "@capacitor/core": "^8.0.0",
    "@capacitor/ios": "^8.0.0",
    "@capacitor/android": "^8.0.0",
    "<plugin-dependency>": "file:../../<plugin-dir>"
  }
}
```

---

## `www/index.html` template (required, one per app)

Every consuming app ships a real test page: a button per method and a result
panel that pretty-prints the resolved value, or shows the `{ code, message }`
on rejection (so the `OS-PLUG-<PLUGIN>-NNNN` error paths are visible too).
Keep it dependency-free (no bundler, no framework) — inline `<script>` only.

The **only** difference between the two stacks is how the plugin is reached and
called:

| Stack | Accessor | Call style |
| --- | --- | --- |
| `app-capacitor-{plugin}` | `window.Capacitor.Plugins.{Plugin}` | Promise: `await Device.getInfo()` |
| `app-cordova-{plugin}` | `window.cordova.plugins.{Plugin}` | Callback: `Device.getInfo(success, failure)` |

Generate one button per method in the agreed spec. For methods that take
options, pass a small hard-coded sample object so the call is exercisable with a
single tap (document the sample inline).

**Capacitor app — `www/index.html`:**

```html
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover" />
    <title>{Plugin} Cap Test</title>
    <style>
      body { font-family: -apple-system, system-ui, sans-serif; margin: 1rem; }
      button { display: block; width: 100%; padding: 0.9rem; margin: 0.4rem 0; font-size: 1rem; }
      pre { background: #111; color: #0f0; padding: 0.75rem; border-radius: 6px;
            white-space: pre-wrap; word-break: break-word; min-height: 6rem; }
    </style>
  </head>
  <body>
    <h1>{npm-package} — test</h1>
    <!-- one <button onclick="run('<method>')">…</button> per method -->
    <button onclick="run('getInfo')">getInfo()</button>
    <pre id="out">Tap a method…</pre>
    <script>
      function show(label, data) {
        document.getElementById('out').textContent = label + '\n' + JSON.stringify(data, null, 2);
      }
      async function run(method) {
        document.getElementById('out').textContent = method + '() …';
        try {
          const P = window.Capacitor && window.Capacitor.Plugins && window.Capacitor.Plugins.{Plugin};
          if (!P) { show('ERROR', '{Plugin} not available (run on device/simulator).'); return; }
          show('✅ ' + method, await P[method](/* sample options if any */));
        } catch (e) { show('❌ ' + method, { message: e.message, code: e.code }); }
      }
    </script>
  </body>
</html>
```

**Cordova app — `www/index.html`** (same markup; swap the `run()` body):

```html
<script>
  function show(label, data) {
    document.getElementById('out').textContent = label + '\n' + JSON.stringify(data, null, 2);
  }
  function run(method) {
    document.getElementById('out').textContent = method + '() …';
    const P = window.cordova && window.cordova.plugins && window.cordova.plugins.{Plugin};
    if (!P) { show('ERROR', '{Plugin} not available (run on device/simulator).'); return; }
    P[method](
      /* sample options if any, */
      function (result) { show('✅ ' + method, result); },
      function (error) { show('❌ ' + method, error); }
    );
  }
</script>
```

After editing `www/`, run `npx cap copy` in the app to push the assets into the
native projects (no `npm run build` of the plugin is needed for a www-only
change). The UI is for the device pass; it does not affect whether the native
build is green.

---

## Procedure (per app)

```bash
cd app-{stack}-{plugin}
npm install
npx cap add android        # if Android SDK present
npx cap add ios            # if Xcode present
# inject required iOS Info.plist usage strings (see below) BEFORE building iOS

# Android — compiles all plugin Kotlin + runs manifest merge:
cd android && ./gradlew :app:assembleDebug && cd ..

# iOS — compiles all plugin Swift (simulator, no signing):
cd ios/App && xcodebuild -project App.xcodeproj -scheme App \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

Both builds run **inside the consuming app** — that is the point of the phase.
The plugin's own `npm run verify:ios` (which builds the plugin's SPM scheme) and
a standalone plugin `assembleDebug` are **not** substitutes: they compile the
plugin in isolation and miss exactly the integration defects this phase exists
to catch (manifest-merge collisions, Cordova-compat wiring, host-app
`Package.swift` rewrite, plugin-registration). Always build the App target/scheme.

If a build fails, **fix the generated plugin** (not the app), re-run, and repeat
until green. `file:` deps are symlinked, so plugin edits are picked up without
re-installing (re-run `npx cap sync` only when manifest/plugin metadata changes).

### iOS Info.plist injection (mandatory before iOS build/run)

The Capacitor plugin documents its required usage strings but the host app must
declare them; without them iOS **hard-crashes** on first access. Read the
plugin's required keys (e.g. from its `ios/NOTES.md` / podspec / Cordova
`plugin.xml` `<config-file>` entries) and add each with a placeholder value to
`app-{stack}-{plugin}/ios/App/App/Info.plist`, e.g.:

```xml
<key>NSCameraUsageDescription</key><string>Test app camera usage.</string>
<key>NSPhotoLibraryUsageDescription</key><string>Test app photo access.</string>
<key>NSPhotoLibraryAddUsageDescription</key><string>Test app saves media.</string>
<key>NSMicrophoneUsageDescription</key><string>Test app records audio.</string>
```

### Cordova plugin shipping a `Package.swift` (SPM-primary iOS deps)

Only relevant when the Cordova plugin declares `<platform name="ios"
package="swift">` and ships its own `Package.swift` — which the unifier does
exactly when iOS has SPM dependencies (Firebase, etc.; see "iOS Dependencies —
SPM-primary" in `unified-structure.md`). Plugins with no iOS SPM deps don't ship
a Cordova `Package.swift` (Capacitor consumes them via the
`capacitor-cordova-ios-plugins/sources/` path) and skip both rules below.

When such a plugin is consumed by a Capacitor app (which is what this phase
does), Capacitor's SPM integration imposes two requirements on the plugin's
`Package.swift`:

1. **`Package(name:)`, the library product, and the target must all equal the
   Cordova plugin id** (`com.outsystems.plugins.{plugin}`). Capacitor's CLI
   generates `.package(name: "{id}", …)` / `.product(name: "{id}", package:
   "{id}")`, so a friendly name like `cordova-outsystems-{plugin}` fails with
   `product '…' not found in package '…'`.

2. **Keep `https://github.com/apache/cordova-ios.git` as the first `apache`
   occurrence in the file.** On `cap sync`/`cap add`, Capacitor rewrites the
   plugin's `Package.swift` in place with
   `.replace('apache','ionic-team').replaceAll('cordova-ios','capacitor-swift-pm')`.
   The `.replace` only hits the *first* `apache`, so any "apache" or
   "cordova-ios" text in a comment above the dependency mangles the URL to the
   unresolvable `https://github.com/apache/capacitor-swift-pm.git`. Don't put
   those substrings in comments before the dependency line.

The shipped (committed) form keeps `apache/cordova-ios` for standalone MABS SPM
builds; Capacitor re-adapts it to `ionic-team/capacitor-swift-pm` locally on
each sync. *(Observed on Capacitor 8.x — these are CLI implementation details
(`@capacitor/cli` `util/spm.js`, `ios/update.js`); re-verify on future majors.)*

---

## Anti-patterns (do NOT do these)

These shortcuts look reasonable and faster but defeat the purpose of the phase —
they are explicitly disallowed:

- ❌ **Verifying the Cordova plugin with a standalone `cordova create` app.**
  The Cordova plugin must be verified as the `app-cordova-{plugin}` **Capacitor**
  app consuming it through the Cordova-compat layer — that is the real
  consumption path (Capacitor apps and ODC), and it is the only way the
  `capacitor-cordova-*-plugins` bridging, the `Package.swift` rewrite, and the
  manifest merge are exercised. A plain Cordova build proves nothing about how
  the plugin behaves where it is actually consumed.
- ❌ **Substituting the plugin's own build for a consuming-app build.** Running
  `npm run verify:ios` (the plugin's SPM scheme) or a standalone plugin
  `assembleDebug` compiles the plugin in isolation. It does not surface
  integration defects (FileProvider/manifest-merge collisions, plugin
  registration, Cordova-compat wiring). Always build the App target/scheme in
  the consuming app.
- ❌ **Scaffolding the apps in `/tmp` or deleting them after the build.** They
  are persisted and reused for the device pass (see the note at the top of this file).
- ❌ **Claiming a platform is build-ready without having run its consuming-app
  build.** Record skipped platforms explicitly (see "Graceful degradation").

---

## Graceful degradation

Build whatever the environment supports; never block on a missing toolchain:

| Condition | Action |
| --- | --- |
| Android SDK present | Run `assembleDebug`. |
| Android SDK missing | Skip; record "Android: not build-verified (no SDK)". |
| Xcode present (macOS) | Run `xcodebuild` for the simulator. |
| Xcode missing / non-macOS | Skip; record "iOS: not build-verified (no Xcode)". |

Do **not** silently claim a platform is build-ready when it was not built.

---

## What this catches (and what it doesn't)

**Caught by the build** (fix in the plugin, then re-run):
- Android `FileProvider` manifest-merge collisions (needs a *consuming app* —
  a standalone plugin `assembleDebug` does not surface this).
- Kotlin compile errors (e.g. error enum thrown as `Throwable`).
- Swift/SPM module-emission errors (e.g. `public` method exposing `internal` type).
- Missing source-file / Activity / permission declarations.
- Gradle dependency and AndroidX/compileSdk mismatches.
- Cordova-plugin `Package.swift` product-name / URL-rewrite mismatches (see the
  iOS subsection above) — only surfaces when the Cordova plugin ships its own
  `Package.swift`.

**NOT caught by the build** (device pass required, list as outstanding):
- Picker/editor UX (e.g. PhotoPicker vs legacy intent, crop-overlay rendering).
- Runtime crashes from missing config or framework session setup
  (e.g. `AVAudioSession`, video playback).
- Permission prompts, capture quality, metadata accuracy, orientation.

---

## Recording results (feeds the Phase 7 summary)

Report, per plugin × platform:

```
capacitor-{plugin}:  Android assembleDebug ✅ | iOS xcodebuild ✅
cordova-{plugin}:    Android assembleDebug ✅ | iOS xcodebuild ✅
Fixes applied during verification: <list>
Not build-verified: <platforms skipped + why>
Device verification: OUTSTANDING — <flows that need a device>
```
