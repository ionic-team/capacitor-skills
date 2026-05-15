---
name: build-actions-generator
description: >-
  Generates OutSystems Developer Cloud (ODC) build action JSON files that
  configure Capacitor mobile plugin builds for Android and iOS. Produces
  correct JSON with platform-specific actions, input variables, and conditional
  logic. Use when a developer says "create a build action for my ODC plugin",
  "generate a buildAction.json file", "set up Gradle or plist build actions for
  a Capacitor or Cordova plugin", "configure AndroidManifest for ODC build", or
  "scaffold ODC native build configuration". If the target platform is
  ambiguous, still generate and note that build actions only apply to ODC —
  they have no effect in standalone Capacitor apps. Do not use when the
  developer explicitly mentions Cordova apps, O11, Cordova extensibility
  configurations, MABS versions prior to 12, or uploading and registering the
  JSON in ODC Studio.
metadata:
  author: ionic
  source: https://github.com/ionic-team/capacitor-skills
---

# ODC Build Actions Generator

Generates a correct `buildAction.json` file for OutSystems Developer Cloud
(ODC) Mobile Libraries (Capacitor and Cordova plugins) and ODC apps. The JSON
file drives the native mobile build process for Capacitor-based apps targeting
Android and iOS via MABS 12 or later.

## Contents

- [When to Use](#when-to-use)
- [What Are Build Actions](#what-are-build-actions)
- [Invocation & Input Signals](#invocation--input-signals)
- [End-to-End Process](#end-to-end-process)
- [JSON File Structure](#json-file-structure)
- [Variables & Conditions](#variables--conditions) *(see reference/variables-and-conditions.md)*
- [Android Actions](#android-actions)
- [iOS Actions](#ios-actions)
- [Generation Guidelines](#generation-guidelines)
- [Complete Example](#complete-example)

---

## When to Use

✅ **Use this skill when:**

- Generating a `buildAction.json` file for an ODC Mobile Library (Capacitor or Cordova plugin).
- Generating a `buildAction.json` file for an ODC app that requires native build configuration.
- Generating build actions for a Cordova plugin being adapted for ODC (Capacitor-based) deployment.
- Configuring `AndroidManifest.xml`, Gradle files, or XML resources for Android.
- Configuring `Info.plist`, entitlements, or display name for iOS.
- Defining input variables (string, number, boolean) and conditional logic.
- Scaffolding build actions for both platforms from a plugin's native requirements.
- Invoked with a plugin path argument or from within a Capacitor or Cordova plugin directory.

❌ **Do NOT use this skill for:**

- Uploading or referencing the JSON in ODC Studio/Portal (Steps 2–3 — see manual guidance).
- Cordova extensibility configurations or O11 extensibility JSON.
- Cordova app builds, O11 builds, or MABS versions prior to 12 — build actions only apply to Capacitor apps on ODC (MABS 12+).
- App-level build configuration that lives outside the build action JSON.
- Publishing or testing the plugin (Step 4 — developer responsibility).

---

## What Are Build Actions

Build actions are JSON-defined transformations applied to the native Capacitor
project **after** `capacitor sync`, during the ODC mobile build. They allow
plugins and libraries to automatically:

- Modify `AndroidManifest.xml` (permissions, attributes, XML injection)
- Patch Gradle files (dependencies, build types)
- Update `Info.plist` (URL schemes, usage descriptions, flags)
- Set entitlements (push notifications, app groups, etc.)
- Inject or replace native code snippets

A single JSON file covers **both platforms**. At least one of `android` or
`ios` must be present under `platforms`.

Build actions are an **ODC-specific mechanism** — they have no effect in
standalone Capacitor apps outside of ODC.

This skill is a **primitive** designed to compose downstream of
`capacitor-plugin-generator` and `cordova-plugin-converter`, so generated or
converted plugins ship with their build configuration already in place.

---

## Invocation & Input Signals

The skill accepts a Capacitor or Cordova plugin as input and writes output to
a `build-actions/` folder at the plugin root.

**Invocation modes:**

- **Path argument** — given a plugin path, writes to `<path>/build-actions/`
- **Current directory** — when invoked inside a plugin directory, writes to `./build-actions/`

**Input signal priority:**

1. **`input-contract.yaml` (preferred)** — If present at the plugin root, read
   its `hooks` section to derive which build actions are required.
2. **Plugin source scanning (fallback)** — When the contract is absent or
   partial, scan the plugin source for native requirement signals:
   - Cordova plugins: parse `plugin.xml` for `<config-file>`, `<hook>`, and permission elements
   - Capacitor plugins: inspect native source files for declared permissions, capabilities, and dependencies

---

## End-to-End Process

This skill handles **Step 1 only**. Steps 2–4 require manual action.

| Step | Owner | What |
|------|-------|------|
| **1. Generate JSON** | This skill | Create `buildAction.json` with all required platform actions |
| **2. Upload JSON** | Developer | Add the file to the plugin/library in ODC Studio → Extensibility Configurations tab |
| **3. Link in Portal** | Developer | Reference the build action in the ODC Portal → Mobile Distribution tab |
| **4. Publish & test** | Developer | Publish the plugin and test a mobile build using MABS 12 (Capacitor) or later |

---

## JSON File Structure

**Output location:** Two files are written to the `build-actions/` folder at
the plugin root:
- `build-actions/buildAction.json` — the build action configuration
- `build-actions/README.md` — human-readable documentation (see Generation Guidelines step 5)

```json
{
  "variables": { },       // optional — input parameters for the build action
  "platforms": {
    "android": { },       // optional — Android-specific actions
    "ios": { }            // optional — iOS-specific actions
  }
}
```

**File naming:** Use camelCase without spaces.

✅ `buildAction.json`, `pushNotifications.json`, `cameraPlugin.json`
❌ `build action.json`, `Build_Action.json`

At least one of `android` or `ios` must be present under `platforms`.

---

## Variables & Conditions

See **[reference/variables-and-conditions.md](reference/variables-and-conditions.md)** for full syntax and examples.

- **Variables** (`"variables"` key) — typed inputs (`string`, `number`, `boolean`) the developer sets in ODC Studio. Always include a `default` unless the value is genuinely required; without one the build fails if unset.
- **Usage** — reference with `$VAR_NAME` anywhere in string values: `"android:name": "com.example.$APP_NAME"`
- **Conditions** — add a `condition` field to any action entry to control whether it runs. Operators: `eq`, `ne`, `gt`, `ge`, `lt`, `le`. Arguments may be variable references or literals.

---

## Android Actions

See **[reference/android-build-actions.md](reference/android-build-actions.md)** for full schemas and examples:

- `appName` — Set the Android app name (string, no condition support)
- `manifest` — Modify `AndroidManifest.xml` (set attributes, merge or inject XML)
- `gradle` — Patch Gradle build files (insert or replace at target DSL path)
- `res` — Create resource files under the `res/` folder
- `json` — Modify JSON files (`set` or `merge`)
- `xml` — Modify arbitrary XML resource files
- `copy` — Copy files, directories, or URLs into the project
- `code` — Add or patch native Android (Java/Kotlin) source files (`source`+`targetDir`, `file`+`target`+`replace`, or `file`+`patchFile`)
- `tar` — Apply tar operations on project files

Quick reference (shown under `platforms.android` — always wrap in `{ "platforms": { "android": { ... } } }`):

```json
"android": {
  "appName":  "$APP_NAME",
  "manifest": [ { "file": "AndroidManifest.xml", "target": "...", "merge": "..." } ],
  "gradle":   [ { "file": "app/build.gradle", "target": { ... }, "replace": { ... } } ],
  "res":      [ { "path": "raw", "file": "config.json", "text": "..." } ],
  "xml":      [ { "file": "res/xml/...", "target": "...", "merge": "..." } ],
  "copy":     [ { "src": "...", "dest": "..." } ],
  "code":     [ { "source": "files/MyClass.java", "targetDir": "src/com/example" } ]
}
```

---

## iOS Actions

See **[reference/ios-build-actions.md](reference/ios-build-actions.md)** for full schemas and examples:

- `displayName` — Set app display name shown on the home screen (no condition support)
- `productName` — Set product name shown in App Store (no condition support)
- `buildSettings` — Set Xcode build settings as key-value pairs
- `buildPhases` — Add or replace custom shell script build phases
- `plist` — Modify `Info.plist` or other plist files (replace or merge entries)
- `xcprivacy` — Update `PrivacyInfo.xcprivacy`
- `entitlements` — Add or modify entitlements (**object**, not array)
- `frameworks` — Add system or custom frameworks to the Xcode project
- `json` — Modify JSON files (`set` or `merge`)
- `xml` — Modify arbitrary XML files
- `copy` — Copy files, directories, or URLs into the project
- `strings` — Update `.strings` localization files
- `xcconfig` — Update `.xcconfig` build configuration files
- `code` — Add or patch native iOS (Swift/Objective-C) source files (`source`+`compilerFlags`, `file`+`target`+`replace`, or `file`+`patchFile`)
- `tar` — Apply tar operations on project files

Quick reference (shown under `platforms.ios` — always wrap in `{ "platforms": { "ios": { ... } } }`):

```json
"ios": {
  "displayName": "$APP_NAME",
  "plist":        [ { "replace": false, "entries": [ { "NSKey": "value" } ] } ],
  "entitlements": { "replace": false, "entries": [ { "aps-environment": "production" } ] },
  "frameworks":   [ { "name": "AudioToolbox.framework" } ],
  "copy":         [ { "src": "...", "dest": "..." } ],
  "code":         [ { "file": "App/AppDelegate.swift", "patchFile": "patches/..." } ]
}
```

---

## Generation Guidelines

### 1. Read plugin input signals

Before asking the developer any questions, check for existing signals in the
plugin:

- If `input-contract.yaml` exists at the plugin root, read its `hooks` section
  to derive which build actions are required.
- If the contract is absent or partial, scan the plugin source:
  - **Cordova plugins:** parse `plugin.xml` for `<config-file>`, `<hook>`, and
    permission declaration elements.
  - **Capacitor plugins:** inspect native source files (Java/Kotlin and
    Swift/Objective-C) for declared permissions, capabilities, and third-party
    dependencies.

### 2. Gather requirements

Ask the developer (or infer from context):

- What native capabilities does the plugin need? (camera, location, push, Bluetooth, etc.)
- Which platforms are targeted: Android only, iOS only, or both?
- Are there runtime configuration values the developer should control? (→ variables)
- Are any actions conditional on those values?

### 3. Map requirements to actions

| Native requirement | Android action | iOS action |
|--------------------|----------------|------------|
| Runtime permission | `manifest` inject `<uses-permission>` | `plist` usage description key |
| Custom URL scheme | `manifest` merge intent-filter | `plist` `CFBundleURLTypes` |
| Custom app attribute | `manifest` attrs | — |
| Native dependency | `gradle` replace | — |
| Push notifications | `manifest` merge + `gradle` | `entitlements` `aps-environment` |
| App groups | — | `entitlements` `com.apple.security.application-groups` |
| Custom display name | — | `displayName` |
| Custom native code | `code` inject/replace | `code` inject/replace |

### 4. Generate the JSON

- Filename: camelCase, no spaces (e.g., `buildAction.json`)
- Only include platforms that have actual actions
- Use `$VAR_NAME` substitution for developer-controlled values
- Include a `default` on variables unless the value is genuinely required from the developer — without one, the build fails if the developer doesn't supply the variable in ODC Studio
- Add `condition` only when an action should be conditionally skipped
- Prefer `merge` over `inject` in `manifest` to avoid duplicate entries
- Output valid, well-formatted JSON
- The `code` action has **platform-specific file path conventions** — iOS targets
  Swift/Objective-C files (e.g., `App/AppDelegate.swift`); Android targets
  Java/Kotlin files (e.g., `app/src/main/java/com/example/App.java`). Do not
  mix conventions between platforms.
- **Prefer config-level actions over `code`** — `manifest`, `gradle`, `plist`,
  `xml`, and `entitlements` cover most native requirements without touching
  source files. Only generate a `code` action when no config-level alternative
  exists. If you do, use `file`+`target`+`replace`; never use `patchFile`.
- **Never generate `code` with `patchFile`** — this variant is unreliable in ODC
  builds. If the change cannot be expressed as a simple string replacement,
  briefly tell the user the approach is not reliable in ODC and suggest a
  Capacitor hook as the alternative (out of scope for this skill). Do not
  explain ODC internals.
- **Avoid `tar` and `copy` when the source file is user-supplied at runtime** —
  these actions are only reliable with hardcoded paths inside the plugin bundle
  or external URLs. If the use case requires user-provided files, briefly tell
  the user to consider a Capacitor hook instead. Do not explain ODC internals.

### 5. Generate the README and wrap up

Generate `build-actions/README.md` alongside the JSON. It serves as
source-control documentation for the plugin and as the primary reference for
the developer setting up ODC. Use this structure:

```markdown
# <Plugin/App Name> Build Actions

<One short paragraph: what this plugin/app does and why native build
configuration is required — inferred from the generated actions.>

## What this configures

### Android
| Action | Purpose |
|--------|---------|
| `<action type>` | <what it sets up> |

### iOS
| Action | Purpose |
|--------|---------|
| `<action type>` | <what it sets up> |

## Variables

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `VAR_NAME` | string | yes | — | What this value controls |

## ODC Setup

1. In ODC Studio, add `buildAction.json` as a resource and set **Deploy Action**
   to **Deploy to Target Directory**.
2. Configure extensibility to reference the file and resolve its variables.
   The path depends on the target:
   - **ODC app:** App > Edit app properties > Extensibility
   - **ODC Mobile Library (plugin):** Library > Edit library properties > Extensibility

   \`\`\`json
   {
       "buildConfigurations": {
           "buildAction": {
               "config": "$resources.buildAction.json",
               "parameters": {
                   "VAR_NAME": "value"
               }
           }
       }
   }
   \`\`\`

3. Build in the ODC Portal using MABS 12 or greater:
   - **ODC app:** build the app directly.
   - **ODC Mobile Library (plugin):** consume the library in an ODC app, then
     build that app.
```

**README authoring rules:**
- Omit the `### Android` or `### iOS` section if that platform has no actions.
- Omit the `## Variables` section entirely if there are no variables.
- In the `## Variables` table, set Required to `yes` if there is no default,
  `no` if a default exists. Leave Default as `—` when Required is `yes`.
- The extensibility JSON in `## ODC Setup` should reflect actual variable names
  from the generated JSON, not placeholder `VAR_NAME`.

**Terminal output after generating both files:**
- Output the generated `buildAction.json` contents.
- Follow with a single short note: *"See `build-actions/README.md` for a
  summary of what this configures and ODC setup instructions."*
- If the developer did not explicitly mention ODC as the target platform, add
  one sentence noting that build actions only take effect in ODC builds, not in
  standalone Capacitor apps.
- Do not repeat the ODC setup steps in the terminal.

---

## Examples

See **[reference/examples.md](reference/examples.md)** for complete, realistic `buildAction.json` files.
