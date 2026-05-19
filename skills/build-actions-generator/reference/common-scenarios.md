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

### Correct approach

Map to a `manifest` build action with a `condition`. The value in the injected
XML is hardcoded (not `$VARIABLE`) because the entry is only relevant at one
specific value — there is no need to pass the variable into the XML string.

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
