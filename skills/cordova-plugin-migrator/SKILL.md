---
name: cordova-plugin-migrator
description: >-
  End-to-end Cordova-to-Capacitor migration orchestrator. Analyzes the
  Cordova plugin (plugin.xml, native iOS/Android source, JS bridge,
  hooks, third-party dependencies), produces a structured migration plan
  as YAML conforming to capacitor-plugin-generator's input contract,
  invokes the generator skill in structured mode at a user checkpoint,
  then consolidates intermediate notes into a single MIGRATION.md. Use
  when the user says "migrate this cordova plugin", "convert cordova to
  capacitor", "assess migration feasibility", "what blocks this
  migration", "port this cordova plugin to capacitor", or "estimate the
  effort to migrate". Do not use for generating new Capacitor plugins
  from scratch (use capacitor-plugin-generator instead), debugging
  runtime issues in an already-migrated plugin, or migrating an entire
  Cordova application; scope is plugin-level only.
metadata:
  author: ionic
  source: https://github.com/ionic-team/capacitor-skills
---

# Cordova Plugin Migrator

End-to-end orchestrator that takes a Cordova plugin source tree and
produces a candidate Capacitor plugin plus a consolidated `MIGRATION.md`,
via a single skill invocation. Internally it analyzes the Cordova plugin,
emits a structured YAML plan conforming to
`capacitor-plugin-generator/references/input-contract.md`, hits a user
checkpoint, then invokes the `capacitor-plugin-generator` skill in
structured mode with that plan. This skill never re-implements what the
generator already does; the generator owns scaffolding and native code
emission.

## When to Use This Skill

✅ **Use this skill when:**

- Migrating an existing Cordova plugin to Capacitor.
- Assessing migration complexity, effort, and blockers before committing.
- Producing the structured handoff YAML for `capacitor-plugin-generator`.
- Comparing the official Cordova API to an existing or planned Capacitor API.
- Auditing a Cordova plugin's hooks, native dependencies, or `<config-file>`
  modifications for portability.

❌ **Do NOT use this skill for:**

- Generating a Capacitor plugin scaffold or implementation, pass the plan to
  `capacitor-plugin-generator`.
- Designing a brand-new plugin without prior Cordova source.
- Migrating entire Cordova apps. Scope is plugin-level only.
- Debugging runtime issues in an already-migrated plugin.
- Publishing or releasing the resulting Capacitor plugin.

## Prerequisites

| Requirement | Use |
| --- | --- |
| Cordova plugin source (local clone or accessible repo) | Read `plugin.xml`, native source, and JS bridge. |
| Node.js LTS and npm | Inspect dependencies, run scripts referenced by hooks. |
| `capacitor-plugin-generator` skill | Receives the YAML plan this skill produces. |
| `capacitor-plugin-generator/references/input-contract.md` | Authoritative shape for the handoff YAML. |
| Read access to the official Capacitor equivalent (if any) | Reuse wire-format names and types when porting a plugin that already exists in Capacitor. |
| Xcode and Android Studio (optional) | Confirm SDK availability for detected native dependencies. |

## Agent Behavior

- Run as an orchestrator. Phases 1–10 analyze the Cordova source and
  produce a YAML plan; Phase 11 invokes `capacitor-plugin-generator` via
  the Skill tool, passing the plan in structured mode; Phase 12
  consolidates documentation. Do not emit native Capacitor code from
  this skill. The generator owns that.
- Read `capacitor-plugin-generator/references/input-contract.md` before
  producing YAML. The generator's contract is authoritative; do not invent
  fields or rename existing ones.
- Resolve the plugin's identity from `plugin.xml` first: id, name, version,
  declared platforms, declared frameworks, hooks, and config-file targets.
- Inspect every native dependency declaration before asserting platform
  support. Mirror what `plugin.xml` actually says, not what the README claims.
- Classify each `<hook>` into Tier 1 (Capacitor hooks), Tier 2 (npm
  scripts/manual steps), or Tier 3 (blocker) using the rules in
  `references/hooks-migration.md`. A single Tier 3 hook is enough to block
  generator handoff.
- When an official Capacitor equivalent exists (`@capacitor/<name>` or a
  Capawesome/community port), read its `definitions.ts` and native source.
  Reuse its wire-format strings, enum values, method names, and event names
  verbatim. Do not invent parallel APIs that "look similar."
- Detect hybrid plugins. If `package.json` already declares `scripts.capacitor:*`
  hooks, the plugin is partially Capacitor-aware. Record the existing hooks
  as Tier 1 "already converted" and ask the user whether to reuse, rewrite,
  or merge them. Do not silently drop them.
- A JS method whose Cordova-side argument is a stringified JSON blob
  (`JSON.parse` / `Gson.fromJson` / `JSONObject(args.getString(0))` in the
  native handler) must be mapped to a strongly-typed TypeScript interface in
  `api.types`, not a `string` parameter. Capture the interface shape from
  the native parsing site.
- When the Cordova native source uses runtime permission APIs
  (`cordova.requestPermission`, `requestPermissions(...)`,
  `AVCaptureDevice.requestAccess`, `PHPhotoLibrary.requestAuthorization`,
  `CLLocationManager` delegates, `CNContactStore.requestAccess`, etc.), add
  `checkPermissions()` and `requestPermissions()` methods to the YAML
  **even if the Cordova JS surface did not expose them**. Capacitor's
  convention is explicit permission methods, and the official equivalent
  (if any) almost always exposes them.
- When the Cordova native source extracts metadata in helper classes
  (`ExifHelper`, `MimeTypeHelper`, `ImageMetadata`, etc.) and includes it
  in the response payload, capture those fields in the corresponding
  `api.types` interface, even if the Cordova JS docs did not document
  them. Read the native code, not the README.
- When mirroring an official Capacitor equivalent, sanity-check the
  official's native LOC against the Cordova source's native LOC. If the
  official is more than 3× larger, add a `migration.notes` entry warning
  the reviewer that a literal port will leave behavior the official
  handles (e.g., iOS `CHHapticEngine` for duration-accurate vibration,
  Android `VibrationEffect` patterns for impact / notification) on the
  floor. The generator's SDK-adapter rule may or may not catch this.
- Distinguish three downstream destinations when emitting setup notes:
  1. **Plugin's own packaging.** Gradle `implementation '...'` lines,
     CocoaPods `s.dependency '...'` lines, custom Maven repo URLs,
     `s.weak_framework`, `s.vendored_frameworks`, AndroidManifest
     `<uses-permission>` / `<meta-data>` / `<queries>` entries, and
     `@CapacitorPlugin(permissions = [...])` declarations all belong
     in the plugin's own `android/build.gradle`, `.podspec`,
     `android/src/main/AndroidManifest.xml`, or annotations. Gradle's
     manifest merger and CocoaPods transitively propagate these to
     consumers, so no host-app step and no `MIGRATION.md` entry is
     required.
  2. **Host-app build configuration.** Items that cannot live in the
     plugin package and must be applied to the consuming app: Info.plist
     privacy strings (`NSCameraUsageDescription`,
     `NSLocationWhenInUseUsageDescription`, etc.), iOS capabilities and
     entitlements (Apple Pay merchant ID, `aps-environment`,
     `com.apple.security.application-groups`), and any other manifest
     mutation that must live on the host app rather than the plugin.
     Record under `migration.notes` and document in `MIGRATION.md` with
     copy-paste-ready snippets per platform.
  3. **Consumer runtime config / code.** Apple Developer-side credential
     provisioning, host-app-supplied JSON config values (merchant
     numbers, API keys), and consumer JS call-site migration (callback
     → Promise, positional → named). No tool can automate these because
     the inputs are the consumer's own data.

  Record each `plugin.xml` directive under one of those three buckets
  in `migration.notes`. Never write a `MIGRATION.md` step that asks
  consumers to add `implementation '...'` for a dep the plugin should
  bundle. See `references/dependency-migration.md` "Ownership Model"
  for the dep-specific table.

- When the Cordova plugin used `<preference name="VAR" default="...">`
  install-time placeholders inside `<config-file target="*-Info.plist">`
  entries (Apple Pay merchant config, OAuth client IDs, analytics keys,
  etc.), detect it and recommend the **runtime config JSON file**
  pattern in `migration.warnings`: a `PluginConfig.json` consumed by a
  hybrid `capacitor:sync:after` script that copies the file into native
  projects at build time. The Cordova plugin may already ship this
  script (look for it in `hooks/capacitor*.js`); if so, reuse it.
  Otherwise propose a one-screen template. This pattern keeps consumer
  values out of static plist / manifest entries entirely.
- Detect SPM markers in `plugin.xml`: `<platform name="ios" package="swift">`
  and `<pod ... nospm="true">` indicate the Cordova plugin already ships a
  sibling `Package.swift`. When present: (a) read that `Package.swift` and
  lift its dependencies into the YAML's `dependencies.ios.spm`, (b) move
  any pod **without** `nospm="true"` to `dependencies.ios.cocoapods`,
  (c) add a `migration.notes` entry that the generated Capacitor plugin
  must ship both `Package.swift` and `.podspec` (Capacitor 8 supports
  both, and SPM is the default for new plugins). See
  `references/dependency-migration.md` "Swift Package Manager (SPM)" for
  the schema.
- Default output mode is Mode B (side-by-side directory). Switch to Mode A
  (in-place with `.cordova-archive/`) only when the user explicitly asks and
  the source is in a writable working copy.
- Stop and request user input when blockers, Tier 3 hooks, unresolvable
  proprietary SDKs, or missing source files would force you to guess. Do not
  emit a YAML plan that hides the gap.
- Distinguish between resolvable warnings (documented manual steps) and
  blockers (cannot be auto-migrated). Both go in the plan; only blockers stop
  handoff.
- A vendored binary checked into the Cordova plugin's tree (e.g.,
  `src/ios/frameworks/Foo.xcframework`) is **not** a blocker on its own. Carry
  the binary forward and record its path under
  `migration.source_files.ios` (or `.android`). Treat as blocker only when
  the binary requires runtime credentials the user does not have or fails
  AndroidX / 64-bit / simulator requirements.
- Report what was actually inspected. Cite file paths and line numbers when
  flagging blockers or unsupported patterns.
- Compare iOS and Android findings against each other before declaring
  Phase 9. If one platform exposes a method the other does not, surface the
  mismatch in `migration.warnings` so the generator can pick a strategy
  (mirror both, expose conditionally, or drop). Do not silently emit a
  contract that only one platform can fulfil.
- Default response shape is **architecture and plan**, not code. Do not
  include full before/after code blocks unless the user explicitly asks for
  "show me the code" or "deep dive". Per-method one-line mappings in
  `migration.cordova_to_capacitor_map` are not "code" in this sense, they
  are part of the plan.
- Quote every value in `migration.cordova_to_capacitor_map` and any other
  YAML string that contains JS syntax (`(`, `)`, `{`, `}`, `:`, `[`, `]`).
  Unquoted JS expressions like `Foo.bar({ x: 1 })` are unparseable YAML and
  the generator will reject the plan at load time.
- Invoke the generator only after the Phase 10 user checkpoint
  approves. If the user rejects, halts, or has unanswered blockers,
  stop. Never invoke the generator with a YAML that has non-empty
  `migration.blockers` or non-empty `migration.hooks.tier_3`.
- When `odc_target: true`, Phase 11 splits into two sequential sub-phases
  (11a and 11b). Phase 11a invokes `build-actions-generator`; Phase 11b
  invokes `capacitor-plugin-generator`. See `references/using-plugin-generator.md`
  "ODC Path" for the full sequence. Build actions are written to the Capacitor
  plugin folder. Hooks and migration notes that are fully covered by build
  actions must be excluded from the YAML passed to the generator (Phase 11b),
  to avoid the generator emitting redundant Capacitor hook scripts for
  config-level work already handled by build actions.

## Procedures

### Phase 1: Determine the Task and Output Mode

Confirm the user has a Cordova plugin to migrate. **If the user wants a
brand-new Capacitor plugin from scratch with no Cordova source to
convert**, stop here and redirect to `capacitor-plugin-generator`
directly, this skill has nothing to add.

Otherwise, pick the output mode:

- **Mode B (default, side-by-side)**, generator scaffolds a new
  Capacitor plugin into a sibling directory of the Cordova repo. The
  Cordova repo is never touched.
- **Mode A (opt-in, in-place)**, generator scaffolds into a temp
  directory. After Phase 11 succeeds, Phase 12 relocates the generator's
  output into the Cordova repo root and moves the original Cordova
  source under `.cordova-archive/`. Preserves the original repo's npm
  package name and git history. Requires explicit user opt-in and a
  clean writable git working copy.

See `references/output-modes.md` for layouts, pre-flight checks, and
the exact relocation sequence.

**ODC confirmation:** Check whether the user mentioned ODC or OutSystems
Developer Cloud anywhere in the request. If yes, set `odc_target: true` and
proceed. If not, ask: *"Will this Capacitor plugin be consumed by an ODC
(OutSystems Developer Cloud) app? If yes, build actions will be generated
alongside the Capacitor plugin to handle native configuration in MABS."*
Record the answer as `odc_target: true/false` for use in Phase 11.

### Phase 2: Read `plugin.xml`

A typical Cordova plugin layout:

```
my-plugin/
├── plugin.xml           # Plugin manifest and configuration
├── package.json         # NPM metadata (and any capacitor:* scripts)
├── www/                 # JavaScript bridge
├── src/
│   ├── ios/             # CDVPlugin subclasses (.h/.m/.swift)
│   └── android/         # CordovaPlugin subclasses (.java/.kt)
└── hooks/               # Optional lifecycle scripts
```

Open `plugin.xml`. Extract: plugin id, name, version, declared platforms
(`<platform name="...">`), `<source-file>`/`<header-file>` mappings,
`<framework>` entries, `<podspec>` blocks, `<config-file>` targets,
`<edit-config>` targets, `<hook>` declarations, `<dependency>` entries,
`<preference>` tags, and `<js-module>` exposure (`clobbers` / `merges` /
`runs`). Record file paths and line numbers for every blocker candidate.

### Phase 3: Analyze Native Dependencies

Apply `references/dependency-migration.md`. For each `<framework>` and
`<podspec>` pod, decide: direct migration, version update, alternative
library, or blocker. For each Android Gradle coord, check AndroidX vs Support
Library and Capacitor's minimum compile SDK. Record manual installation steps
required after migration.

### Phase 4: Analyze Hooks

Apply the three-tier rule in `references/hooks-migration.md`:

- **Tier 1**, convertible to a Capacitor plugin npm hook
  (`capacitor:{sync,copy,update}:{before,after}`,
  `capacitor:{android,ios}:add:{before,after}`).
- **Tier 2**, convertible to an npm lifecycle script (`postinstall`,
  `preuninstall`) or a documented manual step.
- **Tier 3**, interactive prompts, plugin.xml/config.xml mutation, Cordova
  CLI internals, or anything else with no Capacitor equivalent.

Read each referenced script. Do not classify on filename alone.

### Phase 5: Analyze the JavaScript Bridge

Apply `references/api-mappings.md`. From `www/*.js`, list every public method,
its positional argument shape, whether it uses success/error callbacks or
returns a promise, and whether `exec()` is paired with a `cordova.exec()`
action name. Map each method to a Capacitor `methodName(options): Promise<R>`
signature.

### Phase 6: Analyze iOS Implementation

Apply `references/api-mappings.md`. From `src/ios/*.{h,m,swift}`, identify the
`CDVPlugin` subclass, each method matching a JS action, argument extraction
from `command.arguments`, response construction (`CDVPluginResult`), permission
flows, and any system frameworks or SDK adapters used. Note where Objective-C
must be modernized to Swift.

### Phase 7: Analyze Android Implementation

Apply `references/api-mappings.md`. From `src/android/**/*.{java,kt}`,
identify the `CordovaPlugin` subclass, the `execute()` router, action
strings, argument extraction (`args.getString(i)`), response paths
(`CallbackContext.success/error`), permission flows, and any Activity Result
patterns. Note where Java must be modernized to Kotlin.

### Phase 8: Assess Complexity

Apply `references/complexity-assessment.md`. Score the plugin on method count,
LOC, dependency footprint, hook tier mix, language modernization, blocker
count, and Capacitor-equivalent reuse. Output one of: `simple`, `moderate`,
`complex`, `blocked`. `blocked` means the user must resolve issues before
generator handoff.

### Phase 9: Produce the Migration YAML

Apply `references/using-plugin-generator.md`. Build the YAML against the
generator's `references/input-contract.md`, base block (`plugin`,
`platforms`, `api`, `permissions`, `dependencies`) plus the optional
`migration:` block (`source`, `complexity`, `output_mode`, `blockers`,
`warnings`, `language_modernization`, `source_files`, `hooks`,
`cordova_to_capacitor_map`). Pin wire-format strings to the official
Capacitor equivalent when one exists.

### Phase 10: User Checkpoint

Present a short human summary alongside the YAML: complexity, blockers,
warnings, manual setup, recommended output mode, and any Capacitor
equivalent being mirrored. Stop and wait for confirmation if blockers or
Tier 3 hooks are non-empty.

### Phase 11: Invoke Downstream Skills

The downstream invocation path depends on whether ODC was confirmed in Phase 1.

**Non-ODC path:** Apply `references/using-plugin-generator.md`. Invoke
`capacitor-plugin-generator` via the Skill tool in structured mode with the
Phase 9 YAML. The generator runs its own playbook; this skill does not
re-inspect Cordova source. For **Complex** plugins use **incremental mode**
(one platform at a time with user checkpoints). If the generator rejects the
YAML, return to Phase 9 and fix it — never hand-edit generator output.

**ODC path:** Follow the two-sub-phase sequence in
`references/using-plugin-generator.md` "ODC Path":

- **Phase 11a** — Invoke `build-actions-generator` with the Phase 9 YAML
  and the Cordova plugin path; wait for `build-actions/` output. Note which
  hooks/elements it covered.
- **Phase 11b** — Remove build-action-covered items from
  `migration.hooks.tier_1` (or mark `status: handled_by_build_actions`); add
  a `migration.notes` entry documenting this. Then invoke
  `capacitor-plugin-generator` with the annotated YAML (standard or incremental
  per complexity).

### Phase 12: Post-Migration Cleanup

Apply `references/post-migration-cleanup.md`. After the generator produces a
working scaffold, consolidate intermediate notes into a single `MIGRATION.md`
at the plugin root, archive or remove the original Cordova source per the
chosen output mode, and update the README with the consumer-facing breaking
changes (callbacks → promises, positional → named arguments, manual native
setup).

Cross-check that every `migration.notes` and `migration.warnings`
entry is bucketed (plugin packaging / host-app build configuration /
consumer runtime config) per the Agent Behavior rule. The
`MIGRATION.md` should list only items that fall in buckets 2 or 3.
Plugin-packaging items are transparent to consumers and do not belong
in the migration trail.

## Best Practices

### DO

- ✅ Read `plugin.xml` first and ground every claim in actual XML, source
  paths, or hook script content. Cite line numbers for blockers.
- ✅ Treat the generator's input contract as authoritative. Build the YAML
  against `capacitor-plugin-generator/references/input-contract.md`.
- ✅ Reuse wire-format strings from an official Capacitor equivalent when one
  exists. Mirror enum casing, event names, and method names exactly.
- ✅ Classify hooks by reading the referenced script, not by filename.
- ✅ Default to Mode B (side-by-side). Move to Mode A only on explicit user
  opt-in with a writable working copy.
- ✅ Stop at the Phase 10 checkpoint if blockers or Tier 3 hooks exist.
- ✅ Capture both blockers and warnings; only blockers stop handoff.
- ✅ Note manual native setup steps consumers will need after migration
  (Info.plist keys, AndroidManifest entries, Podfile / Gradle additions).

### DON'T

- ❌ Emit native Capacitor code (Swift, Kotlin, Java, TypeScript) from
  this skill. The generator owns code emission.
- ❌ Invent YAML fields or rename ones the generator already defines.
- ❌ Re-derive wire-format strings from human-friendly names when an
  official Capacitor equivalent exists. Read its `definitions.ts`.
- ❌ Classify a hook as Tier 1/2 without opening the referenced script.
- ❌ Emit a YAML plan that lists `complexity: simple` while hiding a
  proprietary AAR or interactive setup hook.
- ❌ Add Capacitor-version-specific guidance here, the generator skill owns
  generator-side rules (name parity, Java filename, `notifyListeners`
  visibility, etc.). Reference, don't duplicate.
- ❌ Invoke the generator silently. Phase 10 is a mandatory user
  checkpoint; do not skip it.
- ❌ Invoke the generator with blockers or Tier 3 hooks unresolved.
- ❌ Commit, push, or publish generator output from this skill.

## Error Handling

| Symptom | Fix |
| --- | --- |
| `plugin.xml` missing or malformed | Stop. Ask for the canonical plugin source. Do not infer a contract from README marketing copy. |
| Source files referenced by `plugin.xml` are not present on disk | Stop. Report missing files by path. The plan is incomplete without them; do not proceed to Phase 9. |
| Hooks reference scripts that cannot be opened or are obfuscated | Classify as Tier 3 and add to `migration.blockers` with the script path. Do not guess based on the hook type. |
| Plugin declares `<framework>` for a private/proprietary AAR or `.framework` requiring runtime credentials the user does not have | Record as a blocker. Note vendor contact requirement. Do not silently swap for a public alternative. |
| Plugin vendors a binary in-tree (e.g., `src/ios/frameworks/Foo.xcframework`, `src/android/libs/Foo.aar`) but it is publicly distributed | Not a blocker. Carry the binary forward and record its path under `migration.source_files.{ios,android}`. The generator copies it into the Capacitor plugin's `ios/` or `android/libs/` directory. |
| Plugin pulls Android deps from a custom Maven repository (Azure DevOps, JFrog, etc.) | Record the URL under `migration.dependencies.android.maven_repos`. Warning, not blocker, when the URL is reachable without auth. Blocker when auth is required and credentials are not provided. |
| Plugin uses Support Library (`android.support.*`) coordinates | Record as a blocker unless Jetifier acceptance is confirmed by the user. Capacitor expects AndroidX. |
| Cordova plugin has an official Capacitor equivalent (`@capacitor/<name>`) | Read the equivalent's `definitions.ts` and native source. Pin method names, enum values, event names, and error codes in the YAML. Add the equivalent's package as `migration.notes` for the reviewer. |
| Plugin declares both `<hook>` entries and `package.json` `scripts.capacitor:*` entries (hybrid plugin) | The Capacitor scripts already exist. Record them as Tier 1 "already converted" hooks. Ask the user whether to reuse, rewrite, or merge them with any newly migrated Cordova hooks. |
| Plugin uses `<config-file>` to mutate `AndroidManifest.xml` with `<uses-permission>`, `<meta-data>`, `<queries>`, or `<provider>` | **Goes in the plugin's own `android/src/main/AndroidManifest.xml`**, Gradle manifest merger merges into the host app automatically. No host-app step. Record under `migration.notes` for the generator to emit. |
| Plugin uses `<config-file>` to mutate `Info.plist` with an Apple-required privacy string (`NSCameraUsageDescription`, `NSLocationWhenInUseUsageDescription`, `NSMicrophoneUsageDescription`, etc.) | **Host-app Info.plist**, Apple App Store requires these on the host app's plist, not the plugin's. Record under `migration.notes` and document a copy-paste snippet in `MIGRATION.md`. |
| Plugin uses `<config-file>` to mutate `Info.plist` with consumer-specific values (Apple Pay merchant ID, OAuth client ID, analytics key) via `$VAR` install-time placeholders | **Runtime config JSON file** pattern is strongly preferred: a `<Plugin>Configuration.json` consumed by a hybrid `capacitor:sync:after` script. Reuse an existing script from the Cordova plugin if present, else propose a one-screen template. Keeps consumer-specific values out of the plist entirely. |
| Plugin uses `<config-file>` to mutate entitlements plists (`*-Debug.plist`, `*-Release.plist`, `*-Entitlements.plist`) for capabilities like `com.apple.developer.in-app-payments`, `aps-environment`, `com.apple.security.application-groups` | **Host-app capability + entitlement.** Record under `migration.notes`; document the exact Xcode capability the consumer must enable (Apple Pay, Push Notifications, App Groups, etc.) and the entitlement value in `MIGRATION.md`. |
| Plugin declares `<framework>` with `weak="true"` for iOS | **Plugin's own podspec.** Record in `dependencies.ios.system_frameworks` and add a `migration.notes` line so the generator emits `s.weak_framework` instead of `s.framework`. No host-app step. |
| Plugin uses `<edit-config>` with `mode="merge"` to add an `android:requestLegacyExternalStorage` or similar attribute to the host `<application>` element | **Host-app AndroidManifest** if the attribute applies to the host app; otherwise plugin's own AndroidManifest. Record in `migration.notes` with the exact attribute and parent so `MIGRATION.md` can include a copy-paste snippet. |
| Plugin uses `<js-module runs="true">` | Add to `migration.warnings`. Recommend an explicit `initialize()` method or constructor-side init in the web layer. |
| Plugin has multiple `<js-module>` entries with multiple `<clobbers>` targets (e.g., constants module + main module) | Collapse into a single `registerPlugin()` registration. Export constants from `definitions.ts` next to the plugin interface. Capacitor has no analog to multi-clobber. |
| Plugin includes Android resource files via `<source-file target-dir="res/...">` | Record under `migration.source_files.android` with the destination `res/` subpath. The generator copies them into `android/src/main/res/<subpath>/`. Common for `FileProvider` paths and themes. |
| Plugin uses `<preference name="..." default="...">` with install-time variable substitution (`${VAR}` in plugin.xml) referenced inside `<config-file target="*-Info.plist">` or `AndroidManifest.xml` | Prefer the **runtime config JSON file** pattern (consumer drops their values into a `<Plugin>Configuration.json` consumed by a hybrid `capacitor:sync:after` script). Reuse an existing script from the Cordova plugin if present. Fallback: `capacitor.config.json` runtime config under `plugins.<PluginJSName>`. |
| Plugin uses `<preference name="ANDROIDX_CORE_VERSION" default="1.18.0">` (or similar build-time-only version pins) referenced inside the plugin's own `build.gradle` | **Plugin's own build.gradle**, pin the version literally in the generated Gradle file. No host-app step, no runtime config. Consumer never sees this. |
| Plugin's native handler parses a stringified JSON blob (`Gson.fromJson`, `JSONObject(args.getString(0))`) | Map the parsed shape to a strongly-typed `api.types` interface, never `string`. Capture the schema from the native parsing site (Kotlin data class or Swift struct). |
| One JS method dispatches to multiple `cordova.exec()` action names based on `typeof param` (e.g., `vibrate(num)` vs `vibrate([...])`) | Split into multiple typed Capacitor methods, `vibrate({ duration })`, `vibrateWithPattern({ pattern, repeat })`, `cancelVibration()`. Record the split in `migration.cordova_to_capacitor_map` and add to `migration.warnings` as a consumer-facing breaking change. |
| Generator rejects YAML with "bad indentation" or "mapping entry" parse error | A `cordova_to_capacitor_map` entry contains unquoted JS syntax (`(`, `{`, `:`, etc.). Quote every `cordova:` and `capacitor:` value as a YAML string. The plan must be re-emitted; the generator cannot load it as-is. |
| Cordova native source requests runtime permissions but the Cordova JS surface has no permission methods | Add `checkPermissions()` (`Promise<PermissionStatus>`) and `requestPermissions(options?)` (`Promise<PermissionStatus>`) to `api.methods`, and a `PermissionStatus` interface to `api.types`. Without these the migrated plugin will violate Capacitor convention and consumers will expect them. |
| Cordova native source has a helper class for metadata extraction (`ExifHelper`, `MimeTypeHelper`, etc.) but the Cordova JS docs don't list the resulting fields | Read the native response-construction site. Add the metadata fields (typically `exif?: any`, `mimeType?`, `size?`) to the result type. The Cordova JS docs frequently understate what the native side actually returns. |
| Official Capacitor equivalent's native source is more than 3× the LOC of the Cordova source | Add a `migration.notes` entry warning the reviewer that a literal port will leave platform-specific behavior unimplemented (e.g., iOS `CHHapticEngine` over `AudioServicesPlaySystemSound`, Android pattern-based haptics over single-shot vibration). Recommend reviewing whether to retarget consumers to the official package. |
| Cordova plugin.xml has `<platform name="ios" package="swift">` or any `<pod ... nospm="true">` | Plugin already ships SPM support alongside CocoaPods. Lift its `Package.swift` dependencies into `dependencies.ios.spm`; lift only pods without `nospm="true"` into `dependencies.ios.cocoapods`. Capacitor port must ship both `Package.swift` and `.podspec`. |
| Plugin declares `<dependency>` on another Cordova plugin | Resolve the dependency target separately. If it lacks a Capacitor equivalent or migration plan, treat as blocker for the current plugin. |
| Plugin's iOS source is Objective-C only | Record `migration.language_modernization.ios: { from: objective_c, to: swift }`. Note bridging headers consumers may still need. |
| Plugin's Android source is Java only | Record `migration.language_modernization.android: { from: java, to: kotlin }`. The generator will still produce Java if the user asks, but Kotlin is the default recommendation. |
| YAML rejected by the generator | Re-read `capacitor-plugin-generator/references/input-contract.md`. Fix the YAML in this skill, not in the generator. Do not work around the contract. |
| Generator flags missing wire-format strings | Re-read the official Capacitor equivalent's `definitions.ts`. Update `api.types` values verbatim. Do not "translate" from the human-friendly names. |
| User requests Mode A but the working copy is not under version control or is read-only | Refuse Mode A. Recommend Mode B. Recovery from a botched in-place move without VCS is manual. |
| Plugin advertises features the source does not implement | Trust the source. Record the advertised-but-unimplemented features under `migration.warnings`. Do not fabricate API methods to match documentation. |
| Hook classified as Tier 1 by filename but actually interactive | Read the script source, not just the `<hook>` `name` attribute. Anything that prompts via stdin, opens a TTY, or shells to `read` / `prompt` is Tier 3. |
| Dep marked "direct migration" but the pod / Gradle artifact is abandoned | Cross-check the latest release date and Swift / AndroidX compatibility before marking as direct. Anything not updated in 3+ years moves to "replace" or "blocker". |
| Complexity assessed "Simple" but plugin has 15+ public API methods | Always count public API methods. Any plugin with more than 10 public methods is at least Moderate, regardless of other signals. |
| Blocker missed during analysis | Always scan `plugin.xml` for `<config-file>`, `<edit-config>`, `<js-module runs="true">`, `<hook>`, and `<dependency>`, these are the non-negotiable blocker candidates. Re-scan before Phase 9 if anything in the YAML looks too tidy. |
| Generator re-reads Cordova source during Phase 11 | The YAML plan is incomplete. Re-validate against `capacitor-plugin-generator/references/input-contract.md`; include JS API signatures, native method mappings, permissions, dependencies, and blockers inline so the generator never has to look at the Cordova tree. |
| User halts at checkpoint due to a blocker they will not accept | Document the blocker in `MIGRATION.md` and stop. Do not invoke the generator. Capture the rejection reason so the next attempt can address it. |
| Complex plugin overwhelms generator context on a single invocation | Use **incremental mode**: invoke the generator once per platform (web → iOS → Android → final) with user checkpoints between each, not once for the whole plugin. See `references/using-plugin-generator.md`. |
| Mode A relocation conflicts with files in the Cordova repo (top-level name collision) | Halt the chain. Either resolve manually with the user (rename, delete, or move conflicting files), or fall back to Mode B by re-running Phase 11 against a sibling directory. |

## Related Skills

- `capacitor-plugin-generator` *(required downstream dependency)*:
  Phase 11 invokes this skill via the Skill tool in structured mode
  with the YAML plan produced in Phase 9. The generator's
  `references/input-contract.md` is the authoritative shape for handoff.
  This skill conforms and cites it but does not duplicate any
  generator-side rules.
- `build-actions-generator` *(optional downstream dependency, ODC path only)*:
  Phase 11a invokes this skill when `odc_target: true`. It generates
  `buildAction.json` for the Capacitor plugin's `build-actions/` directory,
  covering config-level native setup (manifest, plist, Gradle deps,
  entitlements) so the generator does not need to emit Capacitor hook
  equivalents for those items.

## References

- `references/output-modes.md`: Mode A (in-place with `.cordova-archive/`) vs Mode B (side-by-side) directory layouts and `git mv` patterns.
- `references/unsupported-patterns.md`: `<config-file>`, `<edit-config>`, `<hook>`, `<js-module runs>`, preferences, permissions, and per-pattern blocker thresholds.
- `references/dependency-migration.md`: CocoaPods, SPM, system frameworks, Gradle coordinates, AAR/JAR, custom Maven repos, and per-dependency blocker thresholds.
- `references/hooks-migration.md`: Three-tier hook classification (Tier 1 Capacitor hooks, Tier 2 npm scripts, Tier 3 blocker) with script analysis workflow.
- `references/api-mappings.md`: JavaScript bridge, iOS (`CDVPlugin` → `CAPPlugin`), Android (`CordovaPlugin` → `Plugin`), and plugin.xml → package.json conversion.
- `references/migration-patterns.md`: Callback → Promise, permission handling, multi-platform configuration, and consistent error handling across platforms.
- `references/complexity-assessment.md`: Scoring rubric for `simple` / `moderate` / `complex` / `blocked` and the inputs that move a plugin between buckets.
- `references/using-plugin-generator.md`: Building the YAML against `capacitor-plugin-generator/references/input-contract.md`, the `migration:` optional block, and the Phase 11 invocation pattern (standard vs incremental mode).
- `references/post-migration-cleanup.md`: Consolidating intermediate notes into `MIGRATION.md`, the Mode A relocation flow, archiving Cordova source, updating README, and the consumer-facing breaking-change checklist.
- `references/example-analysis.md`: Full worked example end-to-end, plugin.xml read, dependency analysis, hooks classification, YAML output, and generator handoff.
