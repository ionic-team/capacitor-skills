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

Generates `buildAction.json` for ODC Mobile Libraries (Capacitor and Cordova plugins) and ODC apps targeting Android and iOS via MABS 12+.


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

## End-to-End Process

This skill handles **Step 1 only**. Steps 2–4 require manual action.

| Step | Owner | What |
|------|-------|------|
| **1. Generate JSON** | This skill | Create `buildAction.json` with all required platform actions |
| **2. Upload JSON** | Developer | Add the file to the plugin/library in ODC Studio → Resources, and then reference it Extensibility tab, creating Extensibility Settings for any variables. |
| **3. Link in Portal** | Developer | If the build action has parameters, provide values in ODC Portal → Mobile Distribution tab → Extensibility settings |
| **4. Publish & test** | Developer | Test a mobile build using MABS 12 (Capacitor) or later |

---

## JSON File Structure

**Output location:** Two files are written to the `build-actions/` folder at
the plugin root:
- `build-actions/buildAction.json` — the build action configuration
- `build-actions/README.md` — human-readable documentation (see Generation Guidelines step 5)

**Always create `build-actions/` at the top level of the directory provided
(or the current working directory if no path argument was given).** Never
create it inside a subdirectory such as `plugin/`, `android/`, or `ios/`,
even when scanning source files that live in those subdirectories. If the
plugin repo has a nested structure (e.g. `plugin/android/`, `plugin/ios/`),
the output still goes at the repo root: `build-actions/buildAction.json`.

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

If the build action uses variables or conditions, read **`references/variables-and-conditions.md`** for full syntax and examples.

- **Variables** (`"variables"` key) — typed inputs (`string`, `number`, `boolean`) declared by the plugin developer; consuming apps supply values via the extensibility configuration `parameters` block. Always include a `default` unless the value is genuinely required; without one the build fails if unset.
- **Platform-specific variants** — if the same logical value (e.g. an App ID, API key) is used on both Android and iOS but is typically distinct per platform, expose **separate variables** with `_ANDROID` and `_IOS` suffixes (e.g. `ADMOB_APP_ID_ANDROID`, `ADMOB_APP_ID_IOS`). Do not merge them into a single shared variable — the developer must be able to configure each platform independently.
- **Conditions** — add a `condition` field to any action entry (except `displayName`, `productName`, and `appName`) to conditionally skip it; for syntax and operators, see the reference file.

> If variables are defined, read **`references/extensibility-configuration.md`** for how `parameters` in the extensibility configuration supplies values for variables declared in `buildAction.json`. When a library and its consuming app both define build actions, the library's runs first.

---

## Android Actions

If targeting Android, read **`references/android-build-actions.md`** for full action schemas and examples.

Available actions:

- `appName` — Set the Android app name (string, no condition support)
- `manifest` — Modify `AndroidManifest.xml` (set attributes, merge or inject XML)
- `gradle` — Patch Gradle build files (insert or replace at target DSL path)
- `res` — Create resource files under the `res/` folder
- `json` — Modify JSON files (`set` or `merge`)
- `xml` — Modify arbitrary XML resource files
- `copy` — Copy files, directories, or URLs into the project
- `code` — Add or patch native Android (Java/Kotlin) source files (`source`+`targetDir`, `file`+`target`+`replace`, or `file`+`patchFile`)
- `tar` — Apply tar operations on project files

---

## iOS Actions

If targeting iOS, read **`references/ios-build-actions.md`** for full action schemas and examples.

Available actions:

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

---

## Generation Guidelines

### 1. Read plugin input signals

Plugin root is the path argument if one was given, otherwise the current directory. Before asking the developer any questions, check for existing signals in the plugin:

- If `input-contract.yaml` exists at the plugin root, read it against the full
  `capacitor-plugin-generator/references/input-contract.md` schema and extract
  the following relevant sections:
  - `migration.hooks` (`tier_1` / `tier_2` / `tier_3`) — hook classification
    for build-action derivation.
  - `dependencies.android.gradle` and
    `dependencies.ios.{cocoapods,spm,system_frameworks}` — dependency-based
    actions (Gradle patches, framework entries).
  - `permissions.android` and `permissions.ios` — permission actions
    (manifest `<uses-permission>`, plist usage descriptions).
  - `plugin.name` — for the README title.
  - All other fields (`api.methods`, `api.types`, `api.events`, etc.) are
    irrelevant — ignore silently.
- **Always also scan plugin source directly**, even when the contract is
  present. The contract is a starting point; source scanning catches signals
  the contract may not capture or may be stale on:
  - **Cordova plugins:** parse `plugin.xml` — read **`references/cordova-plugin-scanning.md`** for the full element-to-action mapping and hook classification guide.
  - **Capacitor plugins:** scan plugin documentation, `package.json`, and native source files (Java/Kotlin and Swift/Objective-C) — read **`references/capacitor-plugin-scanning.md`** for the full scanning guide.
- When invoked as part of the `cordova-plugin-migrator` ODC flow (Phase 11a),
  the output (`build-actions/`) is written to the **Capacitor plugin
  directory**, not the Cordova source tree. The `cordova-plugin-migrator`
  supplies the Capacitor plugin path as the working directory or argument.

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

> If a hook or element does not map clearly to any action listed above, read **`references/common-scenarios.md`** for patterns that appear unmappable but have correct build action equivalents.

### 4. Generate the JSON

- Filename: camelCase, no spaces (e.g., `buildAction.json`)
- Only include platforms that have actual actions
- Use `$VAR_NAME` substitution for developer-controlled values
- Include a `default` on variables unless the value is genuinely required — without one, the build fails if neither the plugin library nor the consuming app supplies the variable value in the extensibility configuration `parameters`
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
  exists. If you do, use `file`+`target`+`replace`; never use `patchFile` — it
  is unreliable in ODC builds. If the change cannot be expressed as a simple
  string replacement, briefly tell the user the approach is not reliable in ODC
  and suggest a Capacitor hook as the alternative (out of scope for this skill).
  Do not explain ODC internals.
- **Avoid `tar` and `copy` when the source file is user-supplied at runtime** —
  these actions are only reliable with hardcoded paths inside the plugin bundle
  or external URLs. If the use case requires user-provided files, briefly tell
  the user to consider a Capacitor hook instead. Do not explain ODC internals.

After writing the JSON file, validate its syntax before proceeding:

1. Tell the user: *"Validating JSON syntax..."*
2. Try `python3 -m json.tool build-actions/buildAction.json > /dev/null` — use
   this if `python3` is available.
3. If `python3` is not available, try `jq empty build-actions/buildAction.json`.
4. If neither tool is available, self-inspect the file carefully: check for
   balanced braces and brackets, no trailing commas, and correct escaping in
   string values (pay special attention to XML content inside `manifest`/`plist`
   entries where quotes must be escaped as `\"`).
5. If an error is found (by tool or self-inspection), fix the file and repeat
   from step 2 until the JSON is valid.
6. Only proceed to the generation guideline 5 (README) once validation passes.

### 5. Generate the README and wrap up

Generate `build-actions/README.md` alongside the JSON. It serves as
source-control documentation for the plugin and as the primary reference for
the developer setting up ODC. Read **`references/readme-template.md`** for
the required structure, then follow the authoring rules below.

**README authoring rules:**
- Omit the `### Android` or `### iOS` section if that platform has no actions.
- Omit `## What requires additional setup` entirely if all input signals were
  mapped to build actions. Include it only when hooks or elements were found
  that could not be mapped.
- Omit the `## Variables` section entirely if there are no variables.
- Omit the extensibility settings instructions (the paragraph below the JSON block in step 2 of `## ODC Setup`) if the plugin has no variables — the `parameters` key is absent in that case and the instructions have no context.
- In the `## Variables` table, set Required to `yes` if there is no default,
  `no` if a default exists. Leave Default as `—` when Required is `yes`.
- The extensibility JSON in `## ODC Setup` should reflect actual variable names
  from the generated JSON, not placeholder `VAR_NAME`.
- In `## What requires additional setup`, set Recommended approach to:
  - `Capacitor hook` for script-type hooks — describe concretely what the hook must do
  - `ODC resource` for user-supplied files — tell the developer to add the file as an ODC resource in ODC Studio (Deploy Action: Deploy to Target Directory)
  - `Not supported in ODC` for blockers — ODC developers have no access to the native project, so there is no manual fallback; briefly state why rework would be needed
- **Extensibility config permissions alternative**: Only mention `pluginConfigurations.permissions` in the README if (a) the developer explicitly asked about extensibility configurations, or (b) every generated build action is exclusively a `manifest` `<uses-permission>` entry and/or a `plist` iOS usage description entry — meaning the entire `buildAction.json` could be replaced by the `permissions` block in the library extensibility configuration. In all other cases omit it; the reference is in [references/extensibility-configuration.md](references/extensibility-configuration.md).

**Terminal output after generating both files:**
- Do not output the `buildAction.json` contents — the file write already
  displays them.
- Do not show analysis tables, scanning decisions, or per-element reasoning in
  the terminal. Internal reasoning stays internal; noteworthy decisions that did
  not map cleanly belong in the README, not the terminal.
- Output a single short note: *"Build actions written to `build-actions/`. This is a candidate — review `build-actions/buildAction.json` before use, then validate with a MABS 12+ build and functional tests against a real mobile app. See `build-actions/README.md` for a summary of what this configures and ODC setup instructions."*
- If `## What requires additional setup` was written to the README, add one
  additional line: *"Some hooks or elements could not be mapped to build
  actions — see `build-actions/README.md` for details."*
- If the developer did not explicitly mention ODC as the target platform, add
  one sentence noting that build actions only take effect in ODC builds, not in
  standalone Capacitor apps.
- Do not repeat the ODC setup steps in the terminal.

