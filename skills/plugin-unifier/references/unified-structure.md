# Unified Plugin Structure

Authoritative blueprint for the directory structure, naming conventions, and
rules that apply to both plugins in an OutSystems unified dual-stack plugin.

---

## Three-Component Model

Every unified plugin consists of exactly three components:

| Component | Purpose | Audience | Distribution |
|-----------|---------|----------|-------------|
| `capacitor-{plugin}` | Capacitor plugin — TypeScript API + native bridges (no OutSystems code) | OSS community + OutSystems ODC | npm |
| `cordova-outsystems-{plugin}` | Cordova plugin — native bridge for O11 and ODC | OutSystems O11 + ODC | GitHub (git URL) |
| OutSystems Plugin (OML) | Mobile Library wrapping both plugins | OutSystems app developers | OutSystems environment |

The two native plugins are code repositories. The OML is a separate Mobile
Library that lives in an OutSystems environment and consumes both native plugins
via Extensibility Configurations. Native code is embedded inline in each native plugin repo. **The skill never
generates plugins that depend on separate native library repos.** All business
logic is implemented directly inside the plugin using platform SDK APIs. Do not
add dependencies on `ion-android-*`, `ion-ios-*`, or any other intermediate
native library, even if an existing version of the plugin uses one. The goal is a
self-contained plugin that any developer can build without resolving private or
extra repositories. If the developer explicitly requests a native library
dependency, document it clearly but do not generate it as the default.

---

## Sourcing Business Logic from Native Libraries

Often the bulk of an existing plugin's business logic does **not** live in the
plugin repo at all — the bridge is a thin shim that delegates to a separate
native library shipped as a vendored AAR / `.xcframework` / CocoaPod / SPM
package (e.g. `OSBarcodeLib`, `ion-android-*`, `ion-ios-*`). Cloning the plugin
then gives you the API surface and the wiring, but not the camera loop, the
decoder, the editor UI, or the orientation handling — those are inside the
library binary.

Because the generated plugins are **self-contained** (see the Three-Component
Model — no dependency on a separate native library repo), that logic has to be
reimplemented inline. To port it faithfully instead of guessing, you need the
library's source.

**Rule — ask for the library repos.** When you detect that an existing plugin's
implementation lives in a separate native library (its bridge mostly delegates;
`build.gradle` / `podspec` / `Package.swift` pulls in a vendored lib that does
the real work), **ask the developer for access to that library's Android and
iOS source repositories** before generating. State plainly that they are the
authoritative reference for porting the logic inline.

- **If the developer provides access** → read those repos and port the logic
  into each generated plugin (namespace-clean and dependency-free, per the
  OSS-clean rule). This is the preferred path: it preserves behavioral fidelity.
- **If the developer refuses, or the source is genuinely unavailable** →
  **continue as if you don't have access.** Reimplement from the agreed API
  contract, the `cordova-plugin-migrator` analysis, and platform SDK patterns.
  Do **not** block on it. Explicitly flag the reduced behavioral fidelity
  (scanner/editor UI, picker UX, format mappings, orientation, edge cases) as an
  outstanding **device-pass** risk in the Phase 7 summary.

**Porting and licensing.** Copying source into the generated plugin is expected
and encouraged here — do not hold back on "it's proprietary" grounds:

- **Code the developer owns** (the common case for OutSystems libraries): port
  or copy it freely. There is no licensing concern.
- **Open-source library:** copying is fine as long as you comply with its
  license — preserve license/attribution/NOTICE headers, honour any copyleft or
  redistribution terms, and confirm the license is compatible with how the
  plugin will be published.
- **"OSS-clean" describes the result, not the authorship.** It means the output
  carries no OutSystems/Cordova namespaces (except error codes) and no
  dependency on a separate native library repo — it is *not* a prohibition on
  copying. Porting owned or properly-licensed source into the self-contained
  plugin satisfies OSS-clean.

---

## Naming Conventions

`{plugin}` is always **lowercase**. `{Plugin}` is always **PascalCase**.

| Element | Pattern | Example (Camera) |
|---------|---------|-----------------|
| Capacitor repo | `capacitor-{plugin}` | `capacitor-camera` |
| Cordova repo | `cordova-outsystems-{plugin}` | `cordova-outsystems-camera` |
| npm package | `@capacitor/{plugin}` — default, but confirm (see note below) | `@capacitor/camera` |
| Capacitor plugin name (`registerPlugin`) | `{Plugin}` | `Camera` |
| Capacitor Android package | `com.capacitorjs.plugins.{plugin}` | `com.capacitorjs.plugins.camera` |
| Capacitor Android bridge class | `{Plugin}Plugin` | `CameraPlugin` |
| Capacitor Android impl class | `{Plugin}` | `Camera` |
| Other Android classes/files | No specific pattern — depends on purpose | `IONCAMRCameraParameters` |
| Android unit test files | `{Feature}Tests` | `CaptureVideoTests` |
| Capacitor iOS bridge class | `{Plugin}Plugin` | `CameraPlugin` |
| Capacitor iOS impl class | `{Plugin}` | `Camera` |
| Other iOS classes/files | No specific pattern — depends on purpose | `IONCAMRCameraParameters` |
| iOS unit test files | `{Feature}Tests` | `CaptureVideoTests` |
| Cordova plugin ID | `com.outsystems.plugins.{plugin}` | `com.outsystems.plugins.camera` |
| Cordova feature name | `OS{Plugin}Plugin` | `OSCameraPlugin` |
| Cordova Android package | `com.outsystems.plugins.{plugin}` | `com.outsystems.plugins.camera` |
| Cordova Android bridge class | `OS{Plugin}Plugin` | `OSCameraPlugin` |
| Cordova iOS bridge class | `OS{Plugin}Plugin` | `OSCameraPlugin` |
| JS bridge module target | `cordova.plugins.{Plugin}` | `cordova.plugins.Camera` |
| JS bridge source file | `www/js/{plugin}.js` | `www/js/camera.js` |

> **npm package name — default to `@capacitor/{plugin}`, but always confirm.**
> Propose `@capacitor/{plugin}` (e.g. `@capacitor/camera`) as the default, but
> treat it as an explicit Phase 2 confirmation point (see SKILL.md Phase 2) —
> present it and let the developer accept or override before any file is
> written. Never silently invent a different scope such as `@outsystems/…`. The
> developer may override the default, for example with an unscoped
> `capacitor-{plugin}` or a scope they actually control (note that the
> `@capacitor` scope is Ionic-owned and not publishable by third parties, so the
> default name is appropriate for an internal mirror/fork but a public release
> needs a name the developer owns). Whatever name is chosen, it also determines
> the iOS SPM product/package name Capacitor derives
> (`@capacitor/power-profiler` → `CapacitorPowerProfiler`,
> `@scope/capacitor-foo` → `ScopeCapacitorFoo`); keep `Package.swift`'s product
> name in sync with that derivation or `npx cap add ios` fails to resolve the
> package.

---

## Capacitor Plugin Directory Structure

```
capacitor-{plugin}/
├── package.json
├── tsconfig.json
├── rollup.config.js
├── Capacitor{Plugin}.podspec
├── Package.swift
├── README.md
├── src/
│   ├── definitions.ts           ← TypeScript API contract
│   ├── index.ts                 ← plugin registration + re-exports
│   └── web.ts                   ← web implementation
├── android/
│   ├── build.gradle             ← Android dependencies and version targets
│   └── src/
│       ├── main/java/com/capacitorjs/plugins/{plugin}/
│       │   ├── {Plugin}Plugin.kt    ← Capacitor bridge (thin)
│       │   ├── {Plugin}.kt          ← business logic (no Capacitor imports)
│       │   └── {OtherClass}.kt      ← helper classes, extensions, models, etc.
│       └── test/java/com/capacitorjs/plugins/{plugin}/
│           └── {Feature}Tests.kt    ← unit tests
└── ios/
    ├── Plugin/
    │   ├── {Plugin}Plugin.swift     ← Capacitor bridge (thin)
    │   ├── {Plugin}.swift           ← business logic (no Capacitor imports)
    │   └── {OtherClass}.swift       ← helper classes, extensions, models, etc.
    └── PluginTests/
        └── {Feature}Tests.swift     ← unit tests
```

The root scaffold files (`package.json`, `Capacitor{Plugin}.podspec`,
`Package.swift`, `tsconfig.json`, `rollup.config.js`, `android/build.gradle`)
are generated by `npm init @capacitor/plugin`. Do not hand-craft them — use
the CLI output as the baseline.

---

## Cordova Plugin Directory Structure

```
cordova-outsystems-{plugin}/
├── plugin.xml
├── package.json
├── README.md
├── www/
│   └── js/
│       └── {plugin}.js
└── src/
    ├── android/
    │   ├── OS{Plugin}Plugin.kt      ← CordovaPlugin bridge
    │   ├── {Plugin}.kt              ← business logic (no Cordova imports)
    │   └── test/
    │       └── {Feature}Tests.kt    ← unit tests
    └── ios/
        ├── OS{Plugin}Plugin.swift   ← CDVPlugin bridge
        ├── {Plugin}.swift           ← business logic (no Cordova imports)
        └── tests/
            └── {Feature}Tests.swift ← unit tests
```

The outsystems-wrapper is optional and not generated by default. `www/js/{plugin}.js`
is the standard JS bridge and is always present. The outsystems-wrapper is a
separate additional layer only needed when a custom unified JS API is required.
For most plugins, the OML's JS nodes call the Cordova and Capacitor plugins
directly via the runtime conditional pattern. Do not introduce this complexity
unless there is a specific reason.

---

## Bridge / Implementation Separation Rule

Both plugins must separate the framework bridge layer from the business logic.
This applies to every class pair across both native platforms and both plugin types.

- **Capacitor:** `{Plugin}Plugin.kt` / `{Plugin}Plugin.swift` = bridge only.
  `{Plugin}.kt` / `{Plugin}.swift` = logic only, no Capacitor imports.
- **Cordova:** `OS{Plugin}Plugin.kt` / `OS{Plugin}Plugin.swift` = bridge only.
  `{Plugin}.kt` / `{Plugin}.swift` = logic only, no Cordova imports.

---

## Error Code Format

Both plugins must use the OutSystems error code structure for every error they
reject with:

```
OS-PLUG-<PLUGIN>-NNNN
```

Where `<PLUGIN>` is a 4-character uppercase abbreviation of the plugin name
(e.g. `CAMR` for Camera, `PUSH` for Push Notifications) and `NNNN` is a
zero-padded 4-digit number starting at `0001`.

**Rules:**
- Generate a dedicated error enum/class (e.g. `CameraError` on both platforms)
  that lists every error case with its code string and a human-readable message.
- Every `call.reject()` (Capacitor) and `callbackContext.error()` / `sendError()`
  (Cordova) must pass a structured error object containing `code` and `message`.
  Never reject with a plain string.
- The same error codes must be used in both the Capacitor and Cordova plugins —
  they are part of the API contract.
- The error enum must be in the impl class files (e.g. `CameraError.kt`,
  `CameraModels.swift`), not in the bridge files.
- **Kotlin caveat:** a Swift `enum: Error` can be `throw`n/`catch`-ed directly,
  but a Kotlin enum **cannot** (it isn't `Throwable`). Do not `throw CameraError.X`
  in Kotlin — throw/catch an exception wrapper instead. See the
  "Platform Gotchas" section (Android #2) for the
  `class {Plugin}Exception(val error: {Plugin}Error)` pattern.

Example (Kotlin):
```kotlin
enum class CameraError(val code: String, val message: String) {
    TAKE_PHOTO_ERROR("OS-PLUG-CAMR-0001", "An error occurred while taking a photo."),
    GALLERY_PERMISSION_DENIED("OS-PLUG-CAMR-0002", "Gallery permission was denied."),
    CAMERA_PERMISSION_DENIED("OS-PLUG-CAMR-0003", "Camera permission was denied.");

    fun toErrorJson(): JSONObject = JSONObject().apply {
        put("code", code)
        put("message", message)
    }
}
```

---

## OSS-Clean Rule (Capacitor Plugin)

The `capacitor-{plugin}` repo must never contain:

- Any `cordova/exec` or Cordova bridge code.
- Any outsystems-wrapper JS code.
- Any OML file or Mobile Library references.
- Any `OutSystems`-namespaced types, classes, or packages — **except** error
  codes following the `OS-PLUG-<PLUGIN>-NNNN` format defined above.
- Any reference to OutSystems-specific build tools or Extensibility
  Configurations.

---

## Version Targets

Version targets for the Capacitor plugin are automatically scaffolded by
`npm init @capacitor/plugin` for the current Capacitor major version. When
upgrading to a new major version, re-running the CLI scaffold takes precedence
over manually updating these values.

Current targets (Capacitor 8):

| Target | Value |
|--------|-------|
| `@capacitor/core` | `^8.0.0` |
| Android `minSdkVersion` | `24` |
| Android `compileSdkVersion` / `targetSdkVersion` | `36` |
| iOS deployment target | `15.0` |
| Swift version | Matches the version shipped with the current Xcode release (~5.9) |
| Kotlin | `2.2.20` |
| Java | `21` (recommended; 17+ supported) |

---

## iOS Dependencies — SPM-primary

Swift Package Manager is the default iOS dependency manager for new Capacitor
plugins (Capacitor 8 scaffolds `Package.swift` as the primary artifact) and is
Apple's native, bundled manager. CocoaPods is in maintenance mode and being
wound down, so a generated plugin must **never be CocoaPods-only** for a
dependency that ships an SPM distribution.

Rule for the dependency block presented in Phase 2 and applied over the
generator's output in Phase 3:

- **When a dependency offers an SPM distribution, declare it under
  `dependencies.ios.spm` and wire it into `Package.swift`.** CocoaPods/podspec
  is the fallback path, not the primary one.
- **Ship both `Package.swift` and `Capacitor{Plugin}.podspec`,** symmetrically —
  SPM-primary, CocoaPods for consumers still on that path. The
  `npm init @capacitor/plugin` scaffold emits both; keep them in sync.
- **Go CocoaPods-only for a given dependency only when it has no SPM
  distribution.** Record that as the reason so a reviewer can see it was a
  constraint, not a default.

> **`nospm="true"` does not mean "use CocoaPods."** When porting from a Cordova
> plugin whose `plugin.xml` tags a `<pod … nospm="true">` (e.g.
> `FirebaseAnalytics`), that marker means the SPM build path already satisfies
> the dependency via the sibling `Package.swift` — the pod is the CocoaPods-only
> *fallback*. Such a dependency is **SPM-primary** in the port: lift it into
> `dependencies.ios.spm`, not `cocoapods`. Reading `nospm` as "keep CocoaPods"
> inverts its meaning.

---

## Platform Gotchas

Correctness rules that apply to **both** the Capacitor output (apply after the
generator runs, Phase 3) and the Cordova output the unifier writes directly
(Phase 4). Each one corresponds to a defect that the Phase 6 native build (or a
device pass) surfaces if skipped; applying them up front avoids the rework.

### Android

1. **`FileProvider` must be subclassed.** A plugin that declares a bare
   `androidx.core.content.FileProvider` collides (same component name) with the
   host app's / Capacitor's own provider and **fails the manifest merge** in any
   consuming app. Ship a uniquely-named subclass and reference it in the manifest:

   ```kotlin
   class CameraFileProvider : androidx.core.content.FileProvider()
   ```
   ```xml
   <provider android:name="…camera.CameraFileProvider"
             android:authorities="${applicationId}.camera.provider" … />
   ```
   For the Cordova plugin, declare the subclass in `plugin.xml` (both the
   `<config-file>` `<provider>` entry and a `<source-file>` for the `.kt`).

2. **Swift→Kotlin porting pitfall — error enums aren't `Throwable` in Kotlin.**
   A Swift `enum: Error` can be thrown directly; the Kotlin twin can't. Throw/catch
   a wrapper (`class {Plugin}Exception(val error: {Plugin}Error) : Exception(error.message)`)
   instead of `throw {Plugin}Error.X`.

3. **Gallery selection uses the PhotoPicker API, not `ACTION_GET_CONTENT`.**
   On Android 13+ use `ActivityResultContracts.PickVisualMedia` /
   `PickMultipleVisualMedia` (or `Intent(ACTION_PICK_IMAGES)`), which is the
   recommended, privacy-friendly picker and needs **no** runtime permission.
   Do **not** gate picker/SAF flows on `READ_EXTERNAL_STORAGE` (a no-op on 33+).
   Provide a graceful fallback for older APIs.

4. **Full-screen Activities must handle window insets.** Edge-to-edge is enforced
   on SDK 35+, so a custom Activity (e.g. an image editor) will render controls
   under the status/navigation bars unless it pads for insets:

   ```kotlin
   ViewCompat.setOnApplyWindowInsetsListener(root) { v, insets ->
       val b = insets.getInsets(WindowInsetsCompat.Type.systemBars())
       v.setPadding(b.left, b.top, b.right, b.bottom); insets
   }
   ```

### iOS

5. **Swift→Kotlin porting pitfall — SPM visibility.** A `public` method can't
   expose an `internal` type (the Capacitor 8 iOS target is an SPM module), so mark
   shared option/result structs `public` (or keep the methods non-`public` if
   same-module only).

6. **Host-app `Info.plist` usage strings are required.** Camera/photo/mic access
   crashes without `NSCameraUsageDescription`,
   `NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription`,
   `NSMicrophoneUsageDescription`. The plugin can't set these on the host app, so
   (a) document them (Capacitor `ios/NOTES.md`; Cordova `plugin.xml`
   `<config-file target="*-Info.plist">`), and (b) the Phase 6 verification app
   must inject them before building/running iOS.

### Behavioral-fidelity caveat (OSS-clean reimplementations)

When a plugin **reimplements a complex proprietary native library OSS-clean**
(custom crop editor, video player, metadata extraction, etc.), a clean compile
does **not** imply behavioral parity — crop-overlay rendering, video playback
session setup, and picker UX commonly differ. Treat these as device-pass items
and flag them as outstanding in the Phase 7 summary rather than assuming the
ported behavior matches the original.
