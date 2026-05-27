# Capacitor Plugin Scanning Guide

How to derive build actions from a Capacitor plugin's source. Used during
Generation Guidelines step 1 when `input-contract.yaml` is absent or partial.

Scan the plugin in four passes:
1. **Plugin documentation** — extract explicit native setup instructions
2. **package.json** — detect existing hooks
3. **Android native source** — confirm and supplement what documentation describes
4. **iOS native source** — confirm and supplement what documentation describes

---

## What cannot be mapped to build actions

Before scanning, identify items that are out of scope:

**Web/JavaScript code** — `src/` and `www/` contain TypeScript and JavaScript
that runs in the webview. These have no effect on the native build. Skip the
entire `src/` and `www/` trees.

**User-supplied native files** — Build actions cannot accept files as inputs
from the consuming app. If the plugin's README instructs the developer to place
a file like `GoogleService-Info.plist` or `google-services.json` into the
project, that placement cannot be performed by a build action. In ODC,
developers have no access to the native project, so the ODC-compatible approach
is for the developer to add the file as an **ODC resource** in ODC Studio
(Deploy Action: Deploy to Target Directory). Document this as an ODC setup step
in `## What requires additional setup`.

Exception: if the file is bundled inside the plugin itself (not user-supplied),
a `copy` build action can place it. See
[references/android-build-actions.md](references/android-build-actions.md) and
[references/ios-build-actions.md](references/ios-build-actions.md) for `copy`
constraints (hardcoded paths only; user-supplied paths are not reliable in ODC).

**Script-type native logic** — Hooks or setup steps that perform code
generation, SDK initialization, or branching logic beyond what `condition`
expressions support cannot be expressed as build actions. In ODC, developers
have no access to the native project, so a Capacitor hook is the only available
alternative — document these as Capacitor hooks (out of scope for this skill).

Exception: simple code insertions — adding a source file or replacing a string
in an existing one — may be expressible with the `code` build action. See
SKILL.md Generation Guidelines step 4 for constraints and limitations.

---

## Pass 1: Plugin documentation

The plugin's `README.md` (and any `docs/` directory) is the most direct signal.
Look for native setup instructions written for standard Capacitor developers who
have direct native project access — these are the primary candidates for build
actions, because in ODC those steps must be automated rather than performed
manually.

Look for these sections:

- **Android Setup / Android Configuration**
- **iOS Setup / iOS Configuration**
- **Permissions**
- **Entitlements**
- **Installation** (may include native config steps inline)
- **Gradle** or **build.gradle** configuration
- **Xcode** or **Xcode project** changes

**These signals do not need a dedicated section heading.** A single inline
sentence anywhere in the README — e.g. "configure the Privacy - Camera Usage
Description in your Info.plist" or "add the CAMERA permission to your
AndroidManifest" — is a valid plist/manifest signal and must be mapped to a
build action just as if it appeared under a dedicated setup section.

### Mapping documentation content to build actions

| README content | Build action |
|----------------|--------------|
| `AndroidManifest.xml` snippet | `manifest` (prefer `merge`) |
| Gradle dependency or plugin block | `gradle` |
| `Info.plist` key/value | `plist` |
| Entitlements entry | `entitlements` |
| Xcode framework to add | `frameworks` |
| Xcode build setting | `buildSettings` |
| Android XML resource file | `xml` |
| "Add this file to your project" (user-supplied) | Skip — document as ODC resource setup step |

For the full schema and examples of each action type, see:
[references/android-build-actions.md](references/android-build-actions.md) |
[references/ios-build-actions.md](references/ios-build-actions.md)

---

## Pass 2: package.json

### Existing Capacitor hooks

Check the `scripts` section for hook declarations following the Capacitor
lifecycle naming pattern (e.g. `after:sync`, `after:update`, `before:copy`).
Hooks that configure the native project already run during `capacitor sync` in
MABS — **no build action is needed** for the changes those hooks perform.

From each hook declaration, read the referenced script file to understand what
native changes it applies. Those changes are already covered and can be
excluded from build action generation.

**Hook migration** — only if the developer explicitly asks to migrate a hook to
a build action:

| Hook timing | Can migrate? |
|-------------|--------------|
| `after:sync` | ✅ Attempt — runs at end of sync; build actions run after sync |
| `after:update` | ✅ Attempt — same reasoning |
| `before:sync`, `before:copy`, `after:copy`, `before:update` | ❌ No — run during sync; build actions run after sync completes |

Even for migratable hooks, classify the operation first:
- Config-type (manifest patching, plist entries, Gradle changes) → map to the
  appropriate build action using the same approach as Pass 3 and Pass 4
- Script-type (code generation, dependency installs, branching logic) → out of
  scope; the hook must remain as-is

---

## Pass 3: Android native source

### Bundled AndroidManifest.xml

**Before writing any `manifest` build action, open
`android/src/main/AndroidManifest.xml` and read its contents.** If the entry
you are about to generate is already present there, **do not generate a build
action for it** — Capacitor CLI merges the plugin's bundled manifest into the
app manifest automatically during sync, so the entry is already covered.

Only create a `manifest` build action for entries that are:
- Required based on README instructions or source analysis but **absent** from
  the bundled manifest
- Conditionally needed depending on app configuration — use a variable with a
  `condition`; see [references/variables-and-conditions.md](references/variables-and-conditions.md)

Common example: many camera or barcode plugins already declare
`<uses-permission android:name="android.permission.CAMERA" />` in their
bundled `android/src/main/AndroidManifest.xml`. Do not generate a `manifest`
build action for this permission — it is already handled.

### Gradle files

The plugin's own `android/build.gradle` dependencies are applied by Capacitor
CLI during sync. Never generate `gradle` build actions to replicate content
already in the plugin's own build files. Only generate a `gradle` build action
when the plugin's README explicitly states that a change to the root or
app-level `build.gradle` is required as a setup step. Examples of such steps:

- A `maven` repository in the root `allprojects` block
- A `buildscript classpath` dependency in the root `build.gradle`
- An `apply plugin` statement in `app/build.gradle`

Check `android/build.gradle` and `android/variables.gradle` to confirm whether
the plugin already provides the entry before generating a build action for it.

**`variables.gradle` — version variable declarations:** Many plugins ship an
`android/variables.gradle` file that declares SDK version variables (e.g.
`playServicesAdsVersion = "23.0.0"`). These variables are consumed by the
plugin's own `build.gradle` at compile time. If the plugin's README instructs
the developer to set these variables in the app-level `variables.gradle`, they
require a `gradle` build action targeting `variables.gradle` with
`insertType: "variable"`. Read `android/variables.gradle` during scanning and
check the README for any instruction to set version variables at the app level.

**When to hardcode vs. expose as a variable:** Hardcode the version value from
the plugin source (e.g. `"playServicesAdsVersion": "23.0.0"`). Do not expose
internal dependency version pins as developer-facing variables unless the
plugin README explicitly presents them as developer-configurable. Surfacing them
as variables creates unnecessary ODC Studio configuration burden and invites
version mismatches.

**ODC minimum SDK constraints — do not generate build actions that violate these floors:**

- **Android `minSdkVersion`:** MABS 12+ (ODC) enforces a minimum of 28. If a
  plugin's README documents a required `minSdkVersion` ≤ 28, skip the `gradle`
  build action — the ODC floor already satisfies the requirement. Setting a
  value below 28 will break ODC builds or cause runtime failures. Only generate
  a `gradle` action for `minSdkVersion` if the required value is **greater than
  28**, and include a note in the README that the app's minimum Android version
  is being raised above the ODC default.

  **When the README contains a developer-facing `minSdkVersion` instruction that
  is suppressed by the ODC floor**, add a brief note to the generated README so
  the developer is not left wondering whether they need to act. Place it in
  `## What requires additional setup` with reason "Automatically satisfied by
  MABS 12+" and recommended approach "No action required — MABS 12+ enforces a
  minimum SDK of 28, which already meets this requirement." Example row:

  | Hook / element | Reason not mapped | Recommended approach |
  |----------------|-------------------|----------------------|
  | `minSdkVersion = 26` (plugin README) | ODC/MABS 12+ floor (SDK 28) already satisfies this | No action required |
- **Android `compileSdkVersion` and `targetSdkVersion`:** MABS 12+ (ODC)
  enforces `compileSdkVersion` 36 and `targetSdkVersion` 36. Skip any `gradle`
  build action that sets these values at or below those floors — they are
  already satisfied. Only generate a `gradle` action if the required value
  exceeds the MABS floor.
- **iOS deployment target:** MABS 12+ (ODC) enforces a minimum deployment target
  of 15. Do not generate `buildSettings` or `xcconfig` actions that set
  `IPHONEOS_DEPLOYMENT_TARGET` below 15.

### Java / Kotlin source

Scan source files under `android/src/main/java/` or `android/src/main/kotlin/`:

| Signal | What to check |
|--------|---------------|
| `@CapacitorPlugin(permissions = [...])` annotation | Whether those permissions are in the bundled manifest — if yes, skip |
| `checkPermissions` / `requestPermissions` calls | Confirms runtime permissions are required |
| `import android.Manifest` | Permissions used at runtime — verify manifest coverage |
| Third-party SDK imports (e.g. `com.google.*`, `com.firebase.*`) | Gradle dependency — check if plugin's own gradle covers it or if app-level entry is needed |
| `getSystemService(Context.BLUETOOTH_SERVICE)` | Bluetooth permissions — check manifest |
| `getPackageManager().hasSystemFeature(...)` | Hardware feature declaration may be needed |

---

## Pass 4: iOS native source

### Package.swift and .podspec

Framework and library dependencies declared in `Package.swift` (`.package(url:)`)
or a `.podspec` (`s.dependency`) are handled by Capacitor CLI during sync. **No
build action is required** for these. Skip them.

### Swift / Objective-C source

Scan source files under `ios/Sources/` (SPM layout) or `ios/Plugin/` (legacy
CocoaPods layout). Framework imports and API usage are the primary signals for
`plist` usage descriptions and `entitlements` entries:

| Framework import / API usage | Plist key or entitlement needed |
|------------------------------|--------------------------------|
| `import CoreLocation` / `CLLocationManager` | `NSLocationWhenInUseUsageDescription` and/or `NSLocationAlwaysAndWhenInUseUsageDescription` |
| `import AVFoundation` / `AVCaptureDevice` | `NSCameraUsageDescription` |
| `import AVFoundation` / `AVAudioSession` | `NSMicrophoneUsageDescription` |
| `import Contacts` / `CNContactStore` | `NSContactsUsageDescription` |
| `import EventKit` / `EKEventStore` | `NSCalendarsUsageDescription` |
| `import CoreBluetooth` / `CBCentralManager` | `NSBluetoothAlwaysUsageDescription` |
| `import LocalAuthentication` / `LAContext` | `NSFaceIDUsageDescription` |
| `import Photos` / `PHPhotoLibrary` | `NSPhotoLibraryUsageDescription` and/or `NSPhotoLibraryAddUsageDescription` |
| `import CoreMotion` / `CMMotionManager` | `NSMotionUsageDescription` |
| `import CoreNFC` / `NFCReaderSession` | `NFCReaderUsageDescription` + `com.apple.developer.nfc.readersession.formats` entitlement |
| `import HealthKit` / `HKHealthStore` | `NSHealthShareUsageDescription` |
| `import UserNotifications` / `UNUserNotificationCenter` | `aps-environment` entitlement |

The framework import confirms the capability is used. Leave the usage
description text as a variable so the developer can customize it — see
[references/variables-and-conditions.md](references/variables-and-conditions.md).
Infer a sensible default from context where possible (e.g. camera plugin →
`"Used for scanning"`).

**Fixed (non-variable) plist entries:** Not every plist entry is
developer-configurable. Boolean flags and fixed identifiers required by the SDK
(e.g. `GADIsAdManagerApp: true`, `SKAdNetworkItems` with a known network ID)
must still be included as hardcoded plist entries. Do not skip them simply
because they have no variable — they are required for the SDK to function
correctly.

### Entitlements

Look for these patterns in source files or the README:

| Pattern | Entitlement |
|---------|-------------|
| `UNUserNotificationCenter`, `didRegisterForRemoteNotifications` | `aps-environment`: `"development"` or `"production"` |
| `UserDefaults(suiteName:)`, shared containers | `com.apple.security.application-groups` |
| Keychain access (`kSecAttrAccessGroup`) | `keychain-access-groups` |
| Universal links, Handoff | `com.apple.developer.associated-domains` |
| `NFCReaderSession` | `com.apple.developer.nfc.readersession.formats` |

---

## Tracking unmapped items

For every README instruction or source signal that cannot be mapped to a build
action, record:
- The item (README section, hook name, file reference)
- The reason it was not mapped (user-supplied file, script-type hook, no build
  action equivalent)
- The recommended approach (Capacitor hook for script-type logic; ODC resource for user-supplied files; not supported in ODC for blockers)

This list feeds the `## What requires additional setup` section of the
generated README and the one-line terminal note. See Generation Guidelines
step 5 in SKILL.md.

---

## Summary: signal-to-action mapping

| Signal | Build action |
|--------|--------------|
| `src/` / `www/` JavaScript or TypeScript | Skip — web code, not applicable |
| README: `AndroidManifest.xml` snippet | `manifest` |
| README: Gradle dependency / plugin | `gradle` |
| README: `Info.plist` entry | `plist` |
| README: Entitlements entry | `entitlements` |
| README: Add framework in Xcode | `frameworks` |
| README: Xcode build setting | `buildSettings` |
| README: Android XML resource file | `xml` |
| README: Add file to project (user-supplied) | Skip — ODC resource setup step |
| Plugin-bundled file (not user-supplied) | `copy` — hardcoded path inside plugin bundle only |
| Existing `after:sync` / `after:update` hook (config-type) | Skip unless migration explicitly requested |
| Existing hook (script-type) | Skip — retain as Capacitor hook |
| Bundled `android/AndroidManifest.xml` entries | Skip — Capacitor CLI merges during sync |
| Plugin's own `android/build.gradle` dependencies | Skip — Capacitor CLI applies during sync |
| App-level Gradle entry (root or app `build.gradle`) | `gradle` |
| `@CapacitorPlugin(permissions = [...])` + bundled manifest | Skip — already declared |
| iOS framework import + missing plist usage description | `plist` |
| Entitlement usage pattern in source | `entitlements` |
| `Package.swift` / `.podspec` dependencies | Skip — Capacitor CLI handles during sync |
