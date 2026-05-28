# Cordova Plugin Scanning Guide

How to derive build actions from a Cordova plugin's source. Used during
Generation Guidelines step 1 when `input-contract.yaml` is absent or partial.

The primary source of truth is `plugin.xml`. Scan it in two passes:
1. **Declarative config elements** — determine which require build actions vs. what Capacitor CLI already handles during sync
2. **Hook elements** — classify first, then map or defer

---

## Pass 1: Declarative config elements

Build-action-relevant elements are always scoped inside a `<platform>` block:

- Elements inside `<platform name="android">` → map to **Android** build actions only
- Elements inside `<platform name="ios">` → map to **iOS** build actions only

Root-level elements (outside any `<platform>`) do not map to build actions,
with two exceptions: root-level `<hook>` elements apply to both platforms and
are classified in Pass 2; root-level `<preference>` elements may feed into
build action variables — see the `<preference>` section.

Elements not listed in this guide do not apply to build actions and can be
skipped.

### `<config-file>`

The `target` attribute identifies the file to modify; `parent` is the XPath
insertion point. Whether a build action is needed depends on both.

**What Capacitor CLI handles vs. build actions:** Entries marked
*Skip — handled by Capacitor CLI during sync* are the only cases where
Capacitor CLI writes the value automatically — no build action is needed or
appropriate. For all other rows, Capacitor CLI does not write the value; the
build action is the sole mechanism. This matters when a hook conditionally
deletes a value: if that value maps to a non-skip row, making the build action
conditional is sufficient — the key is never added if the action does not run,
so no deletion is needed. See the conditional delete pattern in Pass 2.

**Preferences in CLI-handled entries:** When a skip-row entry uses `$PREF_NAME`,
Capacitor CLI substitutes the preference's `default` value during sync. ODC
developers cannot set preference values through Capacitor CLI — the default is
always applied at sync time. Add a variable and a corresponding build action to
override the CLI-written value after sync. See the `<preference>` section for
the full variable decision logic.

| `target` value | `parent` | Build action |
|----------------|----------|--------------|
| `AndroidManifest.xml` | ends in `application` or `/*` | Skip — handled by Capacitor CLI during sync |
| `AndroidManifest.xml` | any deeper path | `manifest` (use `merge` or `inject`) |
| `*-Info.plist` | any | `plist` |
| `res/xml/*.xml` | any | `xml` with `resFile` (Android) |
| iOS entitlements file (e.g. `Entitlements-Debug.plist`) | any | `entitlements` |
| other iOS plist file (e.g. `GoogleService-Info.plist`) | any | `plist` with `file` |
| Android `res/values/*.xml` or other XML file | any | `xml` with `resFile` or `file` |
| `config.xml` | any | Skip — Cordova-specific, no build action equivalent |
| JSON file (e.g. `google-services.json`) | any | `json` build action |
| any other target | any | Skip — silently ignored by Capacitor CLI; assess case by case, no direct equivalent if not XML, plist, or JSON |

```xml
<!-- parent targets <application> directly → handled by Capacitor CLI, skip -->
<config-file target="AndroidManifest.xml" parent="/manifest/application">
  <activity android:name="com.example.MyActivity" android:exported="true" />
</config-file>

<!-- parent targets manifest root → handled by Capacitor CLI, skip -->
<config-file target="AndroidManifest.xml" parent="/*">
  <uses-permission android:name="android.permission.CAMERA" />
</config-file>

<!-- deeper parent path → build action needed -->
<config-file target="AndroidManifest.xml"
  parent="/manifest/application/activity[@android:name='MainActivity']">
  <intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="myapp" />
  </intent-filter>
</config-file>

<!-- iOS → plist entry -->
<config-file target="*-Info.plist" parent="NSCameraUsageDescription">
  <string>Required for scanning.</string>
</config-file>
```

The `parent` XPath maps directly to the build action `target` field. Prefer
`merge` over `inject` in `manifest` to avoid duplicate entries.

### `<edit-config>`

A newer alternative to `<config-file>` for attribute-level changes. Processed
by Capacitor CLI using the same code paths as `<config-file>`, so the same
`file`/`target` rules apply across all targets:

| `file` value | `target` | Build action |
|--------------|----------|--------------|
| `AndroidManifest.xml` | ends in `application` or `/*` | Skip — handled by Capacitor CLI during sync |
| `AndroidManifest.xml` | any deeper path | `manifest` with `attrs` |
| `*-Info.plist` | any | `plist` |
| iOS entitlements file | any | `entitlements` |
| other iOS plist file | any | `plist` with `file` |
| `config.xml` | any | Skip — Cordova-specific, no build action equivalent |
| JSON file (e.g. `google-services.json`) | any | `json` build action |
| any other file | any | Skip — silently ignored by Capacitor CLI; assess case by case |

```xml
<!-- file targets a specific activity (deeper path) → build action needed -->
<edit-config file="AndroidManifest.xml"
  target="/manifest/application/activity[@android:name='MainActivity']"
  mode="merge">
  <activity android:screenOrientation="portrait" />
</edit-config>
```

### `<framework>`

Fully handled by Capacitor CLI during `capacitor sync` for all relevant
variants (iOS system/custom/lib, Android plain and `gradleReference`).
Android frameworks with other `type` values (e.g. `type="system"`) are silently
ignored by Capacitor CLI and have no build action equivalent. No build action
required. Skip these elements.

**Do not generate iOS `frameworks` build actions for `<framework>` elements in
`plugin.xml`**, even when they reference well-known system frameworks such as
`AssetsLibrary.framework`, `MobileCoreServices.framework`, or
`CoreLocation.framework`. These are handled exclusively by Capacitor CLI during
sync. Generating a `frameworks` build action for them is over-generation and
will duplicate what the build pipeline already applies.

**Gradle build action scope:** The plugin's own Gradle file (applied via
`<framework type="gradleReference">`) is merged by Capacitor CLI during sync.
Never generate `gradle` build actions to replicate content that is already in
the plugin's own build files. Only generate a `gradle` build action when:

- The plugin's documentation explicitly states that a change to the root or
  app-level `build.gradle` is required as a setup step, **or**
- A hook script adds something to `build.gradle` (map the hook per Pass 2).

If neither condition is met, assume the plugin's own Gradle file covers it.

### `<dependency>`

Declares a dependency on another Cordova plugin. In the standard Capacitor CLI,
`<dependency>` elements are validated only — missing dependencies are warned
about but never auto-installed. In MABS Capacitor, declared dependencies are
read and installed automatically. No build action required in either case.
Skip these elements.

### `<podspec>`

iOS only. Handled by Capacitor CLI during `capacitor sync` for CocoaPods-based
projects. For SPM-based projects, `<podspec>` is not read — the plugin requires
a `Package.swift` instead, which is outside the scope of build actions. No
build action required. Skip these elements.

### `<resource-file>` and `<lib-file>`

Fully handled by Capacitor CLI during `capacitor sync` — resource files are
copied to the appropriate native directories automatically. No build action
required. Skip these elements.

### `<source-file>` and `<header-file>`

Fully handled by Capacitor CLI during `capacitor sync` — source and header files
are copied to the appropriate native directories automatically. No build action
required. Skip these elements.

### `<preference>`

A `<preference>` declares a named value substituted as `$PREF_NAME` in other
`plugin.xml` elements. Capacitor CLI only ever uses the `default` attribute —
ODC developers cannot override preference values through Capacitor CLI.

**Step 1 — trace where `$PREF_NAME` is used.** A preference can appear in
three contexts:

- **Declarative elements** (`<config-file>`, `<framework>`, etc.) — use the
  Pass 1 table to determine whether those elements produce build actions.
- **Hook scripts** — classify the hook first using Pass 2, then apply the
  same variable logic if the hook maps to a build action.
- **Runtime JavaScript code** — the preference is read at app runtime, not at
  build time. Not applicable for build actions; skip it.

**Step 2 — add a variable for the preference.** The default rule is: add a
variable for every preference. A variable with a `default` never causes build
failures, and it gives ODC developers the flexibility to override in ODC Studio.

The only case where a variable adds no value is when `$PREF_NAME` is used
exclusively in elements that have no direct build action equivalent whatsoever — for
example, only in `<podspec>` or `config.xml` entries. In that case, no build
action can reference the variable and it can be omitted.

For CLI-handled elements (e.g. `<config-file target="AndroidManifest.xml"
parent="/manifest/application">`): Capacitor CLI writes the value using the
preference default during sync. A build action running after sync can override
that value. Add the variable and the corresponding build action — the build
action default should match the preference default so the behaviour is unchanged
when the developer does not configure it.

**Step 3 — if one or more variables are needed, write them.** A single
`buildAction.json` can declare multiple variables, one per qualifying
preference. See
[references/variables-and-conditions.md](references/variables-and-conditions.md).
Map each `<preference name="X" default="Y">` to a variable `X`: use type
`string` by default, or infer `number`/`boolean` when the default value is
clearly numeric or boolean. Set `default` to the preference's `default`
attribute value. Reference with `$X` in build action string values.

**Boolean variables in plist entries:** A `boolean` variable can be referenced
directly as `"$X"` in a plist entry value — the build actions tool resolves the
correct plist type. A single entry such as
`{ "FirebaseAutomaticScreenReportingEnabled": "$X" }` covers both the `true`
and `false` cases without splitting into two conditional entries.

**Do not use `string` type for boolean preferences**, even if the plugin source
contains a comment about `NSString.boolValue` or stores the value as `"true"` /
`"false"` strings internally. That convention belongs to the Cordova
implementation. In build actions, always use `boolean` type — the tool resolves
the correct plist type automatically. See
[references/common-scenarios.md — "Boolean preference written as a plist string"](common-scenarios.md#pattern-boolean-preference-written-as-a-plist-string)
for the complete pattern.

```xml
<preference name="CLIENT_ID" default="" />
```

→

```json
"variables": {
  "CLIENT_ID": { "type": "string", "default": "" }
}
```

### `<hook>`

Not processed in Pass 1. See **Pass 2** below for hook classification and
build action mapping.

---

## Pass 2: Hook elements

**Reading hook scripts:** Use the exact `src` path from the `<hook>` element to
locate and fetch the script — for example,
`<hook src="hooks/android/setup.js">` is at `hooks/android/setup.js` relative
to the plugin root. Do not guess alternate locations such as `scripts/`.

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
- Adds something to the root or app-level `build.gradle` that is not already
  covered by the plugin's own Gradle file → `gradle`
- Creates or modifies an XML resource → `xml`

Use the Pass 1 element-to-action table as a guide for the specific build action
shape, and the platform reference files for the full schema and examples:
[references/android-build-actions.md](references/android-build-actions.md) |
[references/ios-build-actions.md](references/ios-build-actions.md).

**Pattern: conditional set / conditional delete**

Hooks often branch on a preference value to either set or delete a config entry.
Map these using a `condition` on the build action rather than looking for a
delete equivalent:

- **Conditional set** (`if PREF == true → set VALUE`) → build action with
  `condition: eq($PREF, true)`
- **Conditional delete** (`if PREF == false → delete VALUE`) → identify where
  VALUE was originally added (declarative element or another hook path). If it
  comes from a `<config-file>` or `<edit-config>` element that maps to a build
  action, make that build action conditional with the inverse:
  `condition: ne($PREF, false)`. Because the build action is the sole source of
  the value (Capacitor CLI does not auto-populate `plist` keys or deep manifest
  paths), skipping it means the value is never added — no deletion is needed.

Note: `plist` has no delete operation. `manifest` and `xml` do support `delete`,
but prefer the conditional approach above when the value originates from a
declarative element — it is simpler and avoids ordering dependencies.

See [references/common-scenarios.md](references/common-scenarios.md) for concrete
JSON examples of both patterns.

**Script-type operations → out of scope (Capacitor hook territory):**
- Manages npm/pod dependencies or runs `pod install`
- Performs code generation or asset compilation
- Contains branching logic beyond what build action `condition` expressions
  support
- Uses Cordova context APIs for the operation itself (plugin management,
  platform manipulation) — note: using `context.opts` only to resolve the
  project root, or using `ConfigParser` only to read preference values, does not
  make a hook script-type if the underlying operation is config-type

The `cordova-plugin-migrator` skill classifies these hooks and determines how
they should be handled. The actual implementation — as Capacitor lifecycle hooks
(`capacitor:sync:after`, etc.) or `postinstall` npm scripts — is the
developer's responsibility and outside the scope of build actions.

**Blocker operations → document as not supported in ODC:**
- Requires user input at runtime
- Modifies `plugin.xml` at runtime
- Depends on Cordova-specific internals with no Capacitor equivalent

These cannot be expressed as build actions or Capacitor hooks without
significant rework. ODC developers have no access to the native project, so
there is no manual fallback — these scenarios represent unsupported
functionality that requires plugin redesign.

### Tracking unmapped items

For every hook or element that cannot be mapped to a build action, record:
- The hook type or element name
- The reason it was not mapped (script-type, blocker, non-applicable timing)
- The recommended approach (Capacitor hook for script-type; not supported in ODC for blockers)

This list feeds the `## What requires additional setup` section of the
generated README and the one-line terminal note. See Generation Guidelines
step 5 in SKILL.md.

---

## Summary mapping table

| `plugin.xml` element | Build action |
|----------------------|--------------|
| `<config-file target="AndroidManifest.xml">` (`parent` = `application` or `/*`) | Skip — handled by Capacitor CLI during sync |
| `<config-file target="AndroidManifest.xml">` (deeper `parent`) | `manifest` (merge or inject) |
| `<config-file target="*-Info.plist">` | `plist` |
| `<config-file target="res/xml/...">` | `xml` with `resFile` |
| `<config-file>` targeting iOS entitlements file | `entitlements` |
| `<config-file>` targeting other iOS plist file | `plist` with `file` |
| `<config-file>` targeting Android `res/values/` or other XML file | `xml` with `resFile` or `file` |
| `<config-file>` targeting a JSON file | `json` build action |
| `<config-file>` targeting any other file | Skip — silently ignored by Capacitor CLI; assess case by case |
| `<edit-config file="AndroidManifest.xml">` (`target` = `application` or `/*`) | Skip — handled by Capacitor CLI during sync |
| `<edit-config file="AndroidManifest.xml">` (deeper `target`) | `manifest` (attrs) |
| `<edit-config>` targeting `*-Info.plist` | `plist` |
| `<edit-config>` targeting iOS entitlements file | `entitlements` |
| `<edit-config>` targeting other iOS plist file | `plist` with `file` |
| `<edit-config>` targeting `config.xml` | Skip — Cordova-specific, no build action equivalent |
| `<edit-config>` targeting any other file | Skip — silently ignored by Capacitor CLI; assess case by case |
| `<framework>` (Android plain / `gradleReference`) | Skip — handled by Capacitor CLI during sync |
| `<framework>` (Android other types, e.g. `type="system"`) | Skip — silently ignored by Capacitor CLI, no build action equivalent |
| `<framework>` (iOS) | Skip — handled by Capacitor CLI during sync |
| `<dependency>` | Skip — handled by MABS Capacitor; no build action equivalent |
| `<podspec>` | Skip — handled by Capacitor CLI during sync (CocoaPods); SPM requires `Package.swift`, out of scope |
| `<resource-file>` | Skip — handled by Capacitor CLI during sync |
| `<lib-file>` | Skip — handled by Capacitor CLI during sync |
| `<source-file>` / `<header-file>` | Skip — handled by Capacitor CLI during sync |
| `<preference>` | variable — see `<preference>` section in Pass 1 for full analysis |
| `<hook>` (applicable type, config-type op) | appropriate action — see Pass 2 |
| `<hook>` (applicable type, script-type op) | out of scope → Capacitor hook |
| `<hook>` (applicable type, blocker op) | out of scope → not supported in ODC |
| `<hook>` (non-applicable type) | skip — no equivalent phase in MABS |
