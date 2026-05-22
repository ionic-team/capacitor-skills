# Common Scenarios

Pattern-level reference for mapping Cordova and Capacitor plugin signals to
build actions. Covers recurring patterns that may appear to be unmappable but
have a correct build action equivalent.

Before concluding that a hook or element cannot be expressed as a build action,
check this file.

---

## Pattern: Conditional plist key

### Scenario

A hook conditionally adds or omits a plist key based on a boolean preference.
The hook checks the preference and either writes the key (if `true`) or removes
it (if `false`). A common example is `NSUserTrackingUsageDescription` controlled
by an `EnableAppTrackingTransparencyPrompt` preference.

### Why this appears unmappable

`plist` build actions have no delete operation. Reading "remove
`NSUserTrackingUsageDescription` when `ENABLE_APP_TRACKING_TRANSPARENCY_PROMPT`
is `false`" can lead to the incorrect conclusion that deletion cannot be
expressed as a build action.

### Correct approach

`<config-file target="*-Info.plist">` entries are **never** written by
Capacitor CLI — the build action is the sole source of the plist key. Make the
build action conditional on the preference being `true`. When the condition is
false, the action does not run and the key is never added. No deletion is
needed.

```json
"variables": {
  "ENABLE_APP_TRACKING_TRANSPARENCY_PROMPT": {
    "type": "boolean",
    "default": true
  },
  "USER_TRACKING_DESCRIPTION_IOS": {
    "type": "string",
    "default": "$(PRODUCT_NAME) needs your attention."
  }
}
```

```json
"ios": {
  "plist": [
    {
      "replace": false,
      "condition": "eq($ENABLE_APP_TRACKING_TRANSPARENCY_PROMPT, true)",
      "entries": [
        { "NSUserTrackingUsageDescription": "$USER_TRACKING_DESCRIPTION_IOS" }
      ]
    }
  ]
}
```

This pattern applies to any plist key a hook conditionally sets or omits:
`NSUserTrackingUsageDescription`, permission usage descriptions, feature flags,
and any other `*-Info.plist` entry controlled by a preference.

---

## Pattern: Conditional AndroidManifest meta-data

### Scenario

A hook conditionally adds a `<meta-data>` entry to `AndroidManifest.xml` only
when a boolean preference is set to a specific value — for example, injecting
`firebase_analytics_collection_enabled = false` only when
`ANALYTICS_COLLECTION_ENABLED` is `false`.

### Two valid approaches

**Option A — Conditional injection (hardcoded value):** Only inject the entry
when the value differs from the SDK default. The injected XML hardcodes the
non-default value since the entry is only relevant in that one state.

```json
"android": {
  "manifest": [
    {
      "file": "AndroidManifest.xml",
      "condition": "eq($ANALYTICS_COLLECTION_ENABLED, false)",
      "target": "manifest/application",
      "merge": "<meta-data android:name=\"firebase_analytics_collection_enabled\" android:value=\"false\" />\n"
    }
  ]
}
```

**Option B — Unconditional injection (variable value):** Always inject the
entry using the variable, explicitly declaring the state on every build
regardless of the value.

```json
"android": {
  "manifest": [
    {
      "file": "AndroidManifest.xml",
      "target": "manifest/application",
      "inject": "<meta-data android:name=\"firebase_analytics_collection_enabled\" android:value=\"$ANALYTICS_COLLECTION_ENABLED\" />\n"
    }
  ]
}
```

Both are correct. Option A relies on the SDK default covering the non-injected
case (acceptable when the SDK default matches the variable's default value).
Option B is more explicit and leaves no reliance on SDK defaults. Either is
acceptable as a build action.

---

## Pattern: Boolean preference written as a plist string

### Scenario

A plugin stores a boolean preference as a plist `<string>` entry using the
`NSString boolValue` convention — the value is `"true"` or `"false"` as a
string, parsed as a boolean at runtime. The plugin.xml comment may note this
explicitly.

### Correct approach

Use a `boolean` variable (the default value `true` / `false` makes the type
clear). Reference it with `"$X"` in the plist entry — the build actions tool
resolves the correct plist type. A single entry covers both states without
splitting into two conditional entries.

```json
"variables": {
  "AUTOMATIC_SCREEN_REPORTING_ENABLED": {
    "type": "boolean",
    "default": true
  }
}
```

```json
"ios": {
  "plist": [
    {
      "replace": false,
      "entries": [
        { "FirebaseAutomaticScreenReportingEnabled": "$AUTOMATIC_SCREEN_REPORTING_ENABLED" }
      ]
    }
  ]
}
```

Do **not** split into two entries with `condition: eq($X, true)` and
`condition: eq($X, false)` — a single parameterised entry is sufficient.

---

## Pattern: Local Maven repository for plugin-bundled native libraries

### Scenario

Some plugins (typically commercial or proprietary ones) ship native Android
libraries as AAR files in a `libs/` folder within the plugin bundle. Gradle must
be told where to find those files by adding a `maven { url ... }` entry to the
root `build.gradle` `allprojects.repositories` block. This requirement surfaces
in two ways:

- **Plugin README**: documents an explicit setup step instructing the developer
  to add a `maven { url "${project(':capacitor-my-plugin').projectDir}/libs" }`
  block to the root `build.gradle`.
- **Plugin's own `build.gradle`**: contains a `maven { url ... }` entry that
  uses `${project(':capacitor-my-plugin').projectDir}` as a relative path to its
  own `libs/` folder.

### Why this requires a build action

A `libs/` folder repository using `${project(':plugin-id').projectDir}` must be
declared in the root `build.gradle` `allprojects.repositories` block — the
plugin's own `android/build.gradle`, merged by Capacitor CLI during sync, is not
visible to the consuming project's dependency resolver.

### Correct approach

```json
{
  "platforms": {
    "android": {
      "gradle": [
        {
          "file": "build.gradle",
          "target": { "allprojects": { "repositories": null } },
          "insert": [
            {
              "maven": [
                { "url": "\"${project(':capacitor-my-plugin').projectDir}/libs\"" }
              ]
            }
          ]
        }
      ]
    }
  }
}
```

The double quotes inside the `url` value are part of the Groovy string — Gradle
requires double quotes for GString interpolation. Replace `capacitor-my-plugin` with the actual plugin project name (the Gradle
project identifier, which matches the folder name under `node_modules`).
