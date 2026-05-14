# Android Build Actions Reference

All Android build action types supported in the ODC build actions JSON schema.
These go under `platforms.android` in your `buildAction.json`.

---

## manifest

Modifies `AndroidManifest.xml`. Accepts an array of patch entries.

```json
"android": {
  "manifest": [
    { "file": "AndroidManifest.xml", "target": "...", "attrs": { ... } },
    { "file": "AndroidManifest.xml", "target": "...", "merge": "..." },
    { "file": "AndroidManifest.xml", "target": "...", "inject": "..." }
  ]
}
```

### Entry fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `file` | string | yes | Target file, typically `"AndroidManifest.xml"` |
| `target` | string | yes | XPath-like path to the element, e.g. `"manifest"`, `"manifest/application"` |
| `condition` | string | no | Skip this entry if the expression evaluates to false |
| `attrs` | object | no* | Set or replace attributes on the target element |
| `merge` | string | no* | Merge a raw XML string into the target (deduplication-safe) |
| `inject` | string | no* | Inject a raw XML string into the target (allows duplicates) |

*Exactly one of `attrs`, `merge`, or `inject` per entry.

### attrs — set element attributes

```json
{
  "file": "AndroidManifest.xml",
  "target": "manifest/application",
  "attrs": {
    "android:name": "com.example.MyApplication",
    "android:networkSecurityConfig": "@xml/network_security_config"
  }
}
```

### merge — insert XML block (deduplication-safe)

Use `merge` when the same block must not appear twice.

```json
{
  "file": "AndroidManifest.xml",
  "target": "manifest",
  "merge": "<uses-permission android:name=\"android.permission.CAMERA\" />\n"
}
```

### inject — insert raw XML (allows duplicates)

Use `inject` when the block may legitimately appear more than once.

```json
{
  "file": "AndroidManifest.xml",
  "target": "manifest/application",
  "inject": "<activity android:name=\"com.example.AuthActivity\" />\n"
}
```

### Common manifest patterns

**Grant a runtime permission:**

```json
{
  "file": "AndroidManifest.xml",
  "target": "manifest",
  "merge": "<uses-permission android:name=\"android.permission.RECORD_AUDIO\" />\n"
}
```

**Add a URL scheme intent filter:**

```json
{
  "file": "AndroidManifest.xml",
  "target": "manifest/application/activity",
  "merge": "<intent-filter>\n  <action android:name=\"android.intent.action.VIEW\" />\n  <category android:name=\"android.intent.category.DEFAULT\" />\n  <data android:scheme=\"myapp\" />\n</intent-filter>\n"
}
```

**Declare a package query (Android 11+):**

```json
{
  "file": "AndroidManifest.xml",
  "target": "manifest",
  "merge": "<queries>\n  <package android:name=\"com.google.android.gms\" />\n</queries>\n"
}
```

---

## gradle

Modifies Gradle build files. Accepts an array of patch entries.

```json
"android": {
  "gradle": [
    { ... }
  ]
}
```

### Entry fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `file` | string | yes | Gradle file path, e.g. `"app/build.gradle"` |
| `target` | object | yes | Nested JSON path matching the Gradle DSL structure |
| `replace` | object | yes | Key-value pairs to set at the target location |
| `condition` | string | no | Skip this entry if the expression evaluates to false |

The `target` object mirrors the Gradle DSL hierarchy. Use `null` as a value
to indicate a block (not a leaf), and `replace` to provide actual values.

**Add a Maven dependency:**

```json
{
  "file": "app/build.gradle",
  "target": {
    "dependencies": null
  },
  "replace": {
    "implementation": "'com.example.sdk:sdk:1.2.3'"
  }
}
```

**Set a build type property:**

```json
{
  "file": "app/build.gradle",
  "target": {
    "android": {
      "buildTypes": {
        "release": null
      }
    }
  },
  "replace": {
    "minifyEnabled": "true"
  }
}
```

---

## xml

Modifies arbitrary XML resource files (other than `AndroidManifest.xml`).
Same structure as `manifest` entries — supports `attrs`, `merge`, and `inject`.

```json
"android": {
  "xml": [
    {
      "file": "res/xml/network_security_config.xml",
      "target": "network-security-config",
      "merge": "<domain-config cleartextTrafficPermitted=\"true\"><domain includeSubdomains=\"true\">example.com</domain></domain-config>\n"
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `file` | string | yes | Resource file path relative to the Android project |
| `target` | string | yes | XPath-like element path |
| `condition` | string | no | Conditional execution |
| `attrs` / `merge` / `inject` | string/object | yes* | One of the three patch modes |

---

## code

Injects or replaces native Android (Java/Kotlin) code at a marked location.
Use for changes that cannot be expressed as XML or Gradle patches.

```json
"android": {
  "code": [
    {
      "file": "app/src/main/java/com/example/MyPlugin.java",
      "target": "// BUILD_ACTION_INJECT_HERE",
      "inject": "import com.example.sdk.SdkManager;\n"
    }
  ]
}
```

### Entry fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `file` | string | yes | Source file path relative to the Android project |
| `target` | string | yes | Marker string or pattern to locate the injection point |
| `inject` | string | no* | Code string to insert at the target |
| `replace` | string | no* | Code string to replace the target match |
| `condition` | string | no | Skip this entry if the expression evaluates to false |

*One of `inject` or `replace` required.

**Replace an import block:**

```json
{
  "file": "app/src/main/java/com/example/App.java",
  "target": "import com.old.sdk.OldManager;",
  "replace": "import com.new.sdk.NewManager;"
}
```
