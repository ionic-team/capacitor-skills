# Cordova Plugin Scanning Guide

How to derive build actions from a Cordova plugin's source. Used during
Generation Guidelines step 1 when `input-contract.yaml` is absent or partial.

The primary source of truth is `plugin.xml`. Scan it in two passes:
1. **Declarative config elements** — map directly to build actions
2. **Hook elements** — classify first, then map or defer

---

## Pass 1: Declarative config elements

### `<platform>` wrappers

All elements inside `<platform name="android">` apply to Android only, and
`<platform name="ios">` to iOS only. Elements at the root level of `plugin.xml`
(outside any `<platform>`) apply to both.

### `<config-file>`

The most common source of build actions. The `target` attribute identifies the
file to modify; `parent` is the XPath insertion point.

| `target` value | Build action |
|----------------|--------------|
| `AndroidManifest.xml` | `manifest` (use `merge` or `inject`) |
| `*-Info.plist` | `plist` |
| `res/xml/*.xml` | `xml` (Android) |
| `config.xml` | Skip — Cordova-specific, no build action equivalent |

```xml
<!-- Android → manifest merge -->
<config-file target="AndroidManifest.xml" parent="/manifest/application">
  <activity android:name="com.example.MyActivity" android:exported="true" />
</config-file>

<!-- iOS → plist entry -->
<config-file target="*-Info.plist" parent="NSCameraUsageDescription">
  <string>Required for scanning.</string>
</config-file>
```

The `parent` XPath maps directly to the build action `target` field. Prefer
`merge` over `inject` in `manifest` to avoid duplicate entries.

### `<edit-config>`

A newer alternative to `<config-file>` for attribute-level changes. Maps to
`manifest` with `attrs`.

```xml
<!-- → manifest attrs -->
<edit-config file="AndroidManifest.xml"
  target="/manifest/application/activity[@android:name='MainActivity']"
  mode="merge">
  <activity android:screenOrientation="portrait" />
</edit-config>
```

### `<uses-permission>`

Maps directly to a `manifest` merge.

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

→

```json
{
  "file": "AndroidManifest.xml",
  "target": "manifest",
  "merge": "<uses-permission android:name=\"android.permission.CAMERA\" />\n"
}
```

### `<framework>`

**Android** — maps to `gradle` insert into `dependencies` (Maven coordinate) or
`gradle` insert at top level (local `.gradle` file via `apply plugin`).

```xml
<framework src="com.google.firebase:firebase-messaging:+" />
<framework src="libs/mylib.jar" custom="true" />
```

**iOS** — maps to `frameworks`.

```xml
<framework src="AudioToolbox.framework" />
<framework src="src/ios/MyCustom.framework" custom="true" embed="true" />
```

→

```json
{ "name": "AudioToolbox.framework" }
{ "name": "MyCustom.framework", "customFramework": true, "embed": true }
```

### `<resource-file>`

Maps to `copy` (for generic file placement) or `res` (for Android `res/`
subfolders). Only safe when the source is a bundled file at a fixed path — see
the `copy`/`tar` caveats in the platform reference files.

```xml
<resource-file src="src/android/google-services.json"
               target="app/google-services.json" />
```

→ `copy` with `src` relative to the plugin bundle and `dest` as the target path.

### `<source-file>`

Maps to `code` (add source file variant). Use with caution — prefer config-level
alternatives where possible. See the `code` action caveats in the platform
reference files.

```xml
<source-file src="src/android/MyPlugin.java"
             target-dir="src/com/example/myplugin" />
```

→ `code` with `source` + `targetDir` (Android) or `source` alone (iOS).

### `<preference>`

Cordova preferences that gate behaviour at build time should become build action
variables.

```xml
<preference name="CLIENT_ID" default="" />
```

→ Add a variable `CLIENT_ID` of type `string` with `default: ""` and reference
it as `$CLIENT_ID` in relevant action values.

---

## Pass 2: Hook elements

Not all hooks map to build actions. Classify each `<hook>` before deciding.

### Config-type hooks → build action candidates

Map to a build action when the hook **copies files, patches XML/plist, or adds
Gradle entries**. These are the things build actions do natively and more
reliably.

Common signals:
- Hook reads and writes `AndroidManifest.xml`, `Info.plist`, or other config files
- Hook copies a bundled file (e.g., `google-services.json`) into the native project
- Hook appends a Gradle dependency or applies a plugin

Map these to the appropriate build action (`manifest`, `plist`, `gradle`,
`copy`, `res`, `xml`) using the element tables above as a guide.

### Script-type hooks → out of scope (Capacitor hook territory)

Defer to the `cordova-plugin-migrator` skill when the hook:
- Manages npm/pod dependencies or runs `pod install`
- Performs code generation or asset compilation
- Contains branching logic beyond what build action `condition` expressions support
- Uses Cordova context APIs (`context.opts`, `context.cordova`, etc.)

These are better expressed as Capacitor lifecycle hooks
(`capacitor:sync:after`, etc.) or `postinstall` npm scripts.

### Blocker hooks → document as a manual step

Flag for manual developer action when the hook:
- Interacts with Cordova internals not present in Capacitor
- Requires user input at install time
- Modifies `plugin.xml` at runtime

These cannot be expressed as build actions or Capacitor hooks without
significant rework.

---

## Summary mapping table

| `plugin.xml` element | Build action |
|----------------------|--------------|
| `<config-file target="AndroidManifest.xml">` | `manifest` (merge or inject) |
| `<config-file target="*-Info.plist">` | `plist` |
| `<config-file target="res/xml/...">` | `xml` |
| `<edit-config file="AndroidManifest.xml">` | `manifest` (attrs) |
| `<uses-permission>` | `manifest` merge |
| `<framework>` (Android) | `gradle` |
| `<framework>` (iOS) | `frameworks` |
| `<resource-file>` | `copy` or `res` |
| `<source-file>` | `code` (use with caution) |
| `<preference>` | variable |
| `<hook>` — config-type | appropriate action (classify first) |
| `<hook>` — script-type | out of scope → Capacitor hook |
| `<hook>` — blocker | out of scope → manual step |
| `<config-file target="config.xml">` | skip |
