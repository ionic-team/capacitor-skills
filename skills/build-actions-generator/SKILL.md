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
(ODC) Capacitor and Cordova plugins. The JSON file drives the native mobile
build process for Capacitor-based apps targeting Android and iOS via MABS 12
or later.

## Contents

- [When to Use](#when-to-use)
- [What Are Build Actions](#what-are-build-actions)
- [Invocation & Input Signals](#invocation--input-signals)
- [End-to-End Process](#end-to-end-process)
- [JSON File Structure](#json-file-structure)
- [Variables & Conditions](#variables--conditions)
- [Android Actions](#android-actions)
- [iOS Actions](#ios-actions)
- [Generation Guidelines](#generation-guidelines)
- [Complete Example](#complete-example)

---

## When to Use

✅ **Use this skill when:**

- Generating a `buildAction.json` file for an ODC Capacitor plugin or mobile library.
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
a `.build-actions/` folder at the plugin root.

**Invocation modes:**

- **Path argument** — given a plugin path, writes to `<path>/.build-actions/`
- **Current directory** — when invoked inside a plugin directory, writes to `./.build-actions/`

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

**Output location:** Files are written to the `.build-actions/` folder at the
plugin root (e.g., `.build-actions/buildAction.json`).

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

Variables are optional inputs that developers can set from ODC Studio. They
allow the same build action to behave differently across apps.

```json
"variables": {
  "APP_NAME": {
    "type": "string",
    "default": ""
  },
  "TIMEOUT": {
    "type": "number",
    "default": 30
  },
  "ENABLE_DEBUG": {
    "type": "boolean",
    "default": false
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | yes | `"string"`, `"number"`, or `"boolean"` |
| `default` | any | no | Fallback value used when the developer does not set the variable. Recommended in most cases so the build action has sensible out-of-the-box behavior. Without a default, the developer must supply a value or the build will fail. |

**Usage in values:** Reference variables with `$VAR_NAME` anywhere in string
values inside the JSON.

```json
"attrs": { "android:name": "com.example.$APP_NAME" }
```

**Conditions** control whether an individual action runs. Add a `condition`
field to any action entry using function-style expressions:

| Operator | Meaning | Example |
|----------|---------|---------|
| `eq(a, b)` | equal | `eq($MODE, "prod")` |
| `ne(a, b)` | not equal | `ne($ENV, "dev")` |
| `gt(a, b)` | greater than | `gt($VERSION, 10)` |
| `ge(a, b)` | greater than or equal | `ge($COUNT, 0)` |
| `lt(a, b)` | less than | `lt($TIMEOUT, 60)` |
| `le(a, b)` | less than or equal | `le($LEVEL, 5)` |

Arguments can be variable references (`$VAR_NAME`) or literal values:

```json
{
  "file": "AndroidManifest.xml",
  "condition": "ge($EXAMPLE_NUMBER, 0)",
  "target": "manifest/application",
  "attrs": { "android:name": "com.example.$APP_NAME" }
}
```

---

## Android Actions

See **[reference/android-build-actions.md](reference/android-build-actions.md)** for full schemas and examples:

- `appName` — Set the Android app name (string, supports variable substitution)
- `manifest` — Modify `AndroidManifest.xml` (set attributes, merge or inject XML)
- `gradle` — Patch Gradle build files (target paths, key replacements)
- `xml` — Modify arbitrary XML resource files
- `code` — Inject, replace, or patch native Android (Java/Kotlin) code snippets (`inject`, `replace`, or `patchFile`)

Quick reference:

```json
"android": {
  "appName":  "$APP_NAME",
  "manifest": [ { "file": "AndroidManifest.xml", "target": "...", "merge": "..." } ],
  "gradle":   [ { "file": "app/build.gradle", "target": { ... }, "replace": { ... } } ],
  "xml":      [ { "file": "res/xml/...", "target": "...", "merge": "..." } ],
  "code":     [ { "file": "...", "target": "...", "inject": "..." } ]
}
```

---

## iOS Actions

See **[reference/ios-build-actions.md](reference/ios-build-actions.md)** for full schemas and examples:

- `plist` — Modify `Info.plist` (replace or merge entries)
- `entitlements` — Add or modify entitlement keys
- `displayName` — Override the app display name (string, supports variables)
- `code` — Inject, replace, or patch native iOS (Swift/Objective-C) code snippets (`inject`, `replace`, or `patchFile`)

Quick reference:

```json
"ios": {
  "displayName": "$APP_NAME",
  "plist":        [ { "replace": false, "entries": [ { "NSKey": "value" } ] } ],
  "entitlements": { "replace": false, "entries": [ { "aps-environment": "production" } ] },
  "code":         [ { "file": "...", "condition": "...", "patchFile": "patches/..." } ]
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

### 5. Always summarize the manual steps

After generating the JSON, remind the developer:

> **Next steps (manual):**
> 1. In ODC Studio, add the JSON file as a resource and set **Deploy Action** to **Deploy to Target Directory**.
> 2. Under **App > Edit app properties > Extensibility**, add a `buildConfigurations` entry to reference the file and resolve its variables:
>
> ```json
> {
>     "version": "1",
>     "buildConfigurations": {
>         "buildAction": {
>             "config": "$resources.buildAction.json",
>             "parameters": {
>                 "VAR_NAME": "value"
>             }
>         }
>     }
> }
> ```
>
> 3. Build the app in the ODC Portal using MABS 12 or greater.

> **Output quality:** The generated JSON is candidate-quality and requires
> human review before being uploaded to ODC Studio.

> **ODC only:** If the developer did not explicitly mention ODC as the target
> platform, include a note that build actions only take effect in ODC builds —
> they have no effect in standalone Capacitor apps outside of ODC. This also
> applies when input signals come from a `input-contract.yaml` with Cordova
> hooks, whether user-provided or generated by another skill.

---

## Complete Example

A realistic Microsoft Azure AD / MSAL authentication plugin. Both platforms
register the OAuth redirect scheme, declare authenticator app visibility,
request biometric permissions, and share a keychain token cache.

Both variables are mandatory — there is no sensible default for a per-app
client ID or URL scheme, so the developer must supply them in ODC Studio.

```json
{
  "variables": {
    "CLIENT_ID": {
      "type": "string"
    },
    "APP_SCHEME": {
      "type": "string"
    }
  },
  "platforms": {
    "android": {
      "manifest": [
        {
          "file": "AndroidManifest.xml",
          "target": "manifest",
          "merge": "<queries>\n    <package android:name=\"com.azure.authenticator\" />\n    <package android:name=\"com.microsoft.intune\" />\n    <package android:name=\"com.microsoft.windowsintune.companyportal\" />\n</queries>\n"
        },
        {
          "file": "AndroidManifest.xml",
          "target": "manifest/application",
          "merge": "<activity android:name=\"com.microsoft.identity.client.BrowserTabActivity\" android:exported=\"true\">\n    <intent-filter>\n        <action android:name=\"android.intent.action.VIEW\" />\n        <category android:name=\"android.intent.category.DEFAULT\" />\n        <category android:name=\"android.intent.category.BROWSABLE\" />\n        <data android:scheme=\"msauth\" android:host=\"$CLIENT_ID\" />\n    </intent-filter>\n</activity>\n"
        },
        {
          "file": "AndroidManifest.xml",
          "target": "manifest",
          "merge": "<uses-permission android:name=\"android.permission.USE_BIOMETRIC\" />\n<uses-permission android:name=\"android.permission.USE_FINGERPRINT\" />\n"
        }
      ],
      "gradle": [
        {
          "file": "app/build.gradle",
          "target": {
            "dependencies": null
          },
          "replace": {
            "implementation": "'com.microsoft.identity.client:msal:5.+'"
          }
        }
      ]
    },
    "ios": {
      "plist": [
        {
          "replace": false,
          "entries": [
            {
              "CFBundleURLTypes": [
                {
                  "CFBundleURLSchemes": [
                    "msauth.$CLIENT_ID",
                    "$APP_SCHEME"
                  ]
                }
              ]
            },
            {
              "LSApplicationQueriesSchemes": [
                "msauthv2",
                "msauthv3"
              ]
            },
            {
              "NSFaceIDUsageDescription": "Allows authentication using Face ID."
            }
          ]
        }
      ],
      "entitlements": {
        "replace": false,
        "entries": [
          {
            "keychain-access-groups": [
              "$(AppIdentifierPrefix)com.microsoft.adalcache",
              "$(AppIdentifierPrefix)com.microsoft.identity.universalstorage"
            ]
          }
        ]
      }
    }
  }
}
```
