---
name: build-actions-generator
description: >-
  Generates OutSystems Developer Cloud (ODC) build action JSON files that
  configure Capacitor mobile plugin builds for Android and iOS. Produces
  correct JSON with platform-specific actions, input variables, and conditional
  logic. Use when a developer says "create a build action for my ODC plugin",
  "generate a buildAction.json file", "configure AndroidManifest for ODC build",
  "add a plist entry for iOS in ODC", "set up Gradle build actions for a
  Capacitor plugin", "automate native build config for ODC mobile library",
  "write build actions for MABS 12", or "scaffold ODC native build
  configuration". Do not use for Cordova extensibility configurations, O11
  platform extensibility JSON, installing plugins into apps, app-level
  configuration outside the build phase, or uploading and registering the JSON
  in ODC Studio.
metadata:
  author: ionic
  source: https://github.com/ionic-team/capacitor-skills
---

# ODC Build Actions Generator

Generates a correct `buildAction.json` file for OutSystems Developer Cloud
(ODC) mobile plugins and libraries. The JSON file drives the native mobile
build process for Capacitor-based apps targeting Android and iOS via MABS 12
or later.

## Contents

- [When to Use](#when-to-use)
- [What Are Build Actions](#what-are-build-actions)
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
- Configuring `AndroidManifest.xml`, Gradle files, or XML resources for Android.
- Configuring `Info.plist`, entitlements, or display name for iOS.
- Defining input variables (string, number, boolean) and conditional logic.
- Scaffolding build actions for both platforms from a plugin's native requirements.

❌ **Do NOT use this skill for:**

- Uploading or referencing the JSON in ODC Studio/Portal (Steps 2–3 — see manual guidance).
- Cordova extensibility configurations or O11 extensibility JSON.
- Non-Capacitor mobile plugin setups (MABS < 12).
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
    "type": "string"
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
| `default` | any | no | Value used when the developer does not set the variable |

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

- `manifest` — Modify `AndroidManifest.xml` (set attributes, merge or inject XML)
- `gradle` — Patch Gradle build files (target paths, key replacements)
- `xml` — Modify arbitrary XML resource files
- `code` — Inject or replace native Android (Java/Kotlin) code snippets

Quick reference:

```json
"android": {
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
- `code` — Inject or replace native iOS (Swift/Objective-C) code snippets

Quick reference:

```json
"ios": {
  "displayName": "$APP_NAME",
  "plist":        [ { "replace": false, "entries": [ { "NSKey": "value" } ] } ],
  "entitlements": [ { "replace": false, "entries": [ { "aps-environment": "production" } ] } ],
  "code":         [ { "file": "...", "target": "...", "inject": "..." } ]
}
```

---

## Generation Guidelines

### 1. Gather requirements

Ask the developer (or infer from context):

- What native capabilities does the plugin need? (camera, location, push, Bluetooth, etc.)
- Which platforms are targeted: Android only, iOS only, or both?
- Are there runtime configuration values the developer should control? (→ variables)
- Are any actions conditional on those values?

### 2. Map requirements to actions

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

### 3. Generate the JSON

- Filename: camelCase, no spaces (e.g., `buildAction.json`)
- Only include platforms that have actual actions
- Use `$VAR_NAME` substitution for developer-controlled values
- Add `condition` only when an action should be conditionally skipped
- Prefer `merge` over `inject` in `manifest` to avoid duplicate entries
- Output valid, well-formatted JSON

### 4. Always summarize the manual steps

After generating the JSON, remind the developer:

> **Next steps (manual):**
> 1. Add the JSON file to your ODC plugin/library in ODC Studio → Extensibility Configurations tab
> 2. Reference it in the ODC Portal → Mobile Distribution tab
> 3. Publish the plugin and verify a mobile build using MABS 12 (Capacitor) or later

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
