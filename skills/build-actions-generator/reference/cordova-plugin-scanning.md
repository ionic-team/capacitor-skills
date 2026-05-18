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

Build actions run **after `capacitor sync`**, during the MABS cloud build only,
and execute **once per build**. This shapes which hooks are candidates:

- Hooks that **configure the native project** (patch manifests, copy files, add
  dependencies) are candidates — the config patching still needs to happen at
  build time in MABS, even if it previously ran at install time in Cordova.
- Hooks that run at **deploy, emulate, run, or serve** time have no equivalent
  phase in a MABS build and are not applicable.
- Hooks tied to **development workflow** (platform management, plugin
  install/uninstall, clean) are not applicable.

### Hook type reference

| Hook type | Typical use | Build action suitability |
|-----------|-------------|--------------------------|
| `after_prepare` | Copy config files, patch manifests/plist after sync | ✅ Classify further |
| `before_build` | Pre-build config patching, file setup | ✅ Classify further |
| `before_compile` | Config changes before native compilation | ✅ Classify further |
| `after_plugin_install` | Post-install config setup, file copying | ✅ Classify further — patching still needed at build time |
| `before_plugin_install` | Pre-install checks, validation | ❌ No equivalent phase in MABS |
| `after_build` | Post-build tasks (archive, notify) | ❌ No post-build phase in build actions |
| `after_compile` | Post-compile tasks | ❌ Not applicable |
| `before_plugin_uninstall` | Cleanup on uninstall | ❌ Not applicable |
| `before/after_deploy` | Deploy-time tasks | ❌ Not applicable — MABS does not deploy |
| `before/after_emulate` | Emulator tasks | ❌ Not applicable |
| `before/after_run` | Device run tasks | ❌ Not applicable |
| `before/after_serve` | Dev server tasks | ❌ Not applicable |
| `before/after_clean` | Clean tasks | ❌ Not applicable |
| `before/after_platform_add/rm/ls` | Platform management | ❌ Not applicable |
| `before/after_plugin_add/rm/ls` | Plugin management | ❌ Not applicable |

### For ✅ hook types: classify the operation

Even for applicable hook types, the hook's actual operation determines the
outcome:

**Config-type operations → map to a build action:**
- Copies a bundled config file into the native project → `copy` or `res`
- Patches `AndroidManifest.xml` → `manifest`
- Patches `Info.plist` → `plist`
- Adds a Gradle dependency or applies a plugin → `gradle`
- Creates or modifies an XML resource → `xml`

Use the Pass 1 element-to-action table as a guide for the specific build action
shape.

**Script-type operations → out of scope (Capacitor hook territory):**
- Manages npm/pod dependencies or runs `pod install`
- Performs code generation or asset compilation
- Contains branching logic beyond what build action `condition` expressions
  support
- Uses Cordova context APIs (`context.opts`, `context.cordova`, etc.)

The `cordova-plugin-migrator` skill classifies these hooks and determines how
they should be handled. The actual implementation — as Capacitor lifecycle hooks
(`capacitor:sync:after`, etc.) or `postinstall` npm scripts — is the
developer's responsibility and outside the scope of build actions.

**Blocker operations → document as a manual step:**
- Requires user input at runtime
- Modifies `plugin.xml` at runtime
- Depends on Cordova-specific internals with no Capacitor equivalent

These cannot be expressed as build actions or Capacitor hooks without
significant rework.

### Tracking unmapped items

For every hook or element that cannot be mapped to a build action, record:
- The hook type or element name
- The reason it was not mapped (script-type, blocker, non-applicable timing)
- The recommended approach (Capacitor hook or manual step)

This list feeds the `## What requires additional setup` section of the
generated README and the one-line terminal note. See Generation Guidelines
step 5 in SKILL.md.

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
| `<hook>` (applicable type, config-type op) | appropriate action — see Pass 2 |
| `<hook>` (applicable type, script-type op) | out of scope → Capacitor hook |
| `<hook>` (applicable type, blocker op) | out of scope → manual step |
| `<hook>` (non-applicable type) | skip — no equivalent phase in MABS |
| `<config-file target="config.xml">` | skip |
