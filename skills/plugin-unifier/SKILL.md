---
name: plugin-unifier
description: >-
  Generates both the Capacitor and Cordova plugin sides of an OutSystems unified
  dual-stack plugin from a single agreed API spec. Use when a user says "generate
  a unified plugin for X", "create the Cordova and Capacitor plugin for X",
  "scaffold a unified plugin", "generate the OutSystems plugins for X feature",
  "the Cordova plugin exists, generate the Capacitor plugin too", "align the APIs
  of these two plugins", or "unify these plugins". Do not use for generating a
  standalone Capacitor plugin with no OutSystems Cordova counterpart (use
  capacitor-plugin-generator instead), migrating a Cordova plugin to Capacitor
  without the OutSystems structure (use cordova-plugin-migrator instead), or for
  publishing production-ready code without human review.
metadata:
  author: ionic
  source: https://github.com/ionic-team/capacitor-skills
---

# Plugin Unifier

Generates two unified OutSystems plugins from a single agreed API spec: a
Capacitor plugin (OSS, npm-published, used by the Capacitor community and
OutSystems ODC) and a Cordova plugin (OutSystems-specific, installed via git
URL, used by OutSystems O11 and ODC). Both plugins expose identical method
names, option keys, return shapes, and permission models. This skill
orchestrates the `capacitor-plugin-generator` skill for the Capacitor side and
generates the Cordova side directly, applying the OutSystems unified plugin
structure overlay throughout.

## When to Use This Skill

✅ **Use this skill when:**

- Generating both a Capacitor and a Cordova plugin for a new OutSystems feature.
- One plugin exists and the other needs to be created from it.
- Both plugins exist but their APIs have diverged and need to be unified.
- Aligning an existing plugin pair to the OutSystems unified plugin architecture.

❌ **Do NOT use this skill for:**

- Generating a standalone Capacitor plugin with no OutSystems Cordova counterpart
  (use `capacitor-plugin-generator` instead).
- Migrating a Cordova plugin to Capacitor outside the OutSystems unified
  structure (use `cordova-plugin-migrator` instead).
- Publishing production-ready code without human review.
- Generating the OutSystems Plugin OML / ODC bindings. That is **phase 2**, not
  yet implemented, and is delivered separately. When authored, phase 2 will
  **invoke the `odc-bindings-generator` skill** rather than generating bindings
  inline. Do not attempt OML/ODC binding generation from this skill yet.

## Prerequisites

| Requirement | Use |
| --- | --- |
| Node.js LTS and npm | Run the Capacitor plugin generator and package scripts. |
| Xcode | Build and verify iOS output when iOS is targeted. |
| Android Studio and Android SDK | Build and verify Android output when Android is targeted. |
| `capacitor-plugin-generator` skill | Generates the Capacitor plugin side from the agreed spec. |
| `cordova-plugin-migrator` skill | Analyzes an existing Cordova plugin's API surface (Scenario 2/3 only). |

## Agent Behavior

### Mandatory Sub-Skill Invocation (non-negotiable)

`plugin-unifier` is an **orchestrator**. Its value is delegating analysis and
Capacitor generation to two specialist skills so their logic stays in one place
and their future fixes reach unified plugins automatically. Reimplementing their
work inline defeats that purpose and causes drift.

Therefore:

- You **MUST call the Skill tool** to invoke `cordova-plugin-migrator` (when a
  Cordova plugin exists — Scenario 2/3) and `capacitor-plugin-generator` (Phase
  3, every scenario). **Reading a sub-skill's `references/` files and applying
  them by hand is NOT a substitute for invoking it** and is explicitly
  prohibited.
- Do **NOT** analyze the Cordova source yourself when `cordova-plugin-migrator`
  applies. Do **NOT** scaffold, design the TypeScript contract, or write the
  Capacitor native bridges yourself — that is `capacitor-plugin-generator`'s job.
- **Announce each invocation before making it**, on its own line, so a skipped
  hand-off is visible in the transcript. Use exactly:
  - `Invoking cordova-plugin-migrator to analyze the existing Cordova plugin…`
  - `Invoking capacitor-plugin-generator in structured mode (Phase 3)…`
- **Surface the named artifact each sub-skill returns** before continuing: the
  migrator's migration YAML (and any blockers/warnings), and the generator's
  scaffold result. If you cannot show that artifact, you did not invoke the
  skill — stop and invoke it.
- The only sanctioned exception is a sub-skill being genuinely unavailable in
  the environment. In that case, **stop and tell the user** the skill is
  missing and ask how to proceed — do not silently fall back to doing the work
  inline.

### General

- Read `references/scenario-detection.md` before doing anything else. Detect
  the scenario (Scenario 1: both new; Scenario 2: one exists; Scenario 3: both
  diverged) and apply the matching procedure.
- Never proceed to code generation without an explicit user confirmation of the
  agreed API spec.
- For the Capacitor plugin side, **invoke** the `capacitor-plugin-generator`
  skill in structured mode with the agreed spec (see the mandatory rule above).
  Do not re-implement what that skill already handles (scaffolding, TypeScript
  API design, web layer, native bridges).
- For the Cordova plugin side, generate directly using the templates and rules
  in `references/cordova-generation.md`. (This is the one side the unifier owns
  — there is no Cordova generator skill to delegate to.)
- Apply the unified structure overlay from `references/unified-structure.md` to
  both generated repos.
- When an existing plugin's business logic lives in a **separate native library**
  (its bridge mostly delegates to a vendored AAR / `.xcframework` / pod / SPM
  package such as `OSBarcodeLib` or `ion-*`), **ask the developer for access to
  that library's Android and iOS source repos** to use as the porting reference,
  then port the logic inline. If they decline or the source is unavailable,
  continue as if without it and flag the reduced behavioral fidelity. See
  "Sourcing Business Logic from Native Libraries" in
  `references/unified-structure.md`.
- Verify API parity using the rules in `references/api-parity.md` before
  declaring Phase 1 complete.
- After parity, run **Phase 6 native build verification** (`references/build-verification.md`):
  build each generated plugin in a consuming app on every available platform
  before declaring it build-ready. Apply the "Platform Gotchas" checklist
  (`references/unified-structure.md`) up front so the build passes first time.
  Distinguish build verification from device verification, and record which
  platforms were actually built.
- Phase 2 (OML generation) is a separate invocation. Do not start it without
  explicit user confirmation that Phase 1 output is satisfactory.

## Procedures

### Phase 1: Detect the Scenario

Read `references/scenario-detection.md`. Determine which scenario applies:

- **Scenario 1** — Both plugins are new: infer or accept the API spec directly.
- **Scenario 2** — One plugin exists: read the existing plugin's API surface. If
  the existing plugin is Cordova, you **MUST invoke `cordova-plugin-migrator`**
  (via the Skill tool) to analyze it and extract the API surface — announce it
  first (`Invoking cordova-plugin-migrator to analyze the existing Cordova
  plugin…`) and surface the migration YAML it returns. Do not read `plugin.xml`,
  the JS bridge, or native source yourself to derive the API. If the existing
  plugin is Capacitor, read `src/definitions.ts` directly (no migrator needed).
- **Scenario 3** — Both plugins exist but are diverged: **invoke
  `cordova-plugin-migrator`** (via the Skill tool, announced as above) on the
  Cordova side, read `src/definitions.ts` from the Capacitor side, produce a
  side-by-side comparison, and surface every conflict for user resolution. Do
  not auto-resolve conflicts.

Invoking the migrator is mandatory whenever a Cordova plugin exists, even when
you intend to redesign the API with the user afterward — its extracted surface,
blockers, and warnings are the baseline the redesign is reconciled against.

While detecting the scenario, also check **where the business logic lives**. If
the existing plugin's native bridge mostly delegates to a separate native
library (a vendored AAR / `.xcframework` / pod / SPM package — the migrator will
typically flag the dependency), the cloned repo does **not** contain the real
implementation. In that case ask the developer for access to the library's
Android and iOS source repos to port from; if they decline or it is unavailable,
continue without it and record the behavioral-fidelity gap for the Phase 7
summary. See "Sourcing Business Logic from Native Libraries" in
`references/unified-structure.md`.

### Phase 2: Confirm the API Spec

Present the agreed API to the user in a structured format (plugin name, **npm
package name**, method signatures, option types, result types, enums, permission
model). Ask for explicit confirmation before generating. See
`references/scenario-detection.md` for the presentation format and conflict
resolution procedure for Scenario 3.

For the **npm package name**, default to `@capacitor/{plugin}` but always
confirm it — present the default and let the developer accept or override before
any file is written. Never silently invent a different scope (e.g.
`@outsystems/…`). The developer may override (an unscoped `capacitor-{plugin}`
or a scope they control; note `@capacitor` is Ionic-owned and unpublishable by
third parties, so it suits an internal mirror but a public release needs a name
the developer owns). See the "npm package name" note in
`references/unified-structure.md` (it also drives the iOS SPM product name).

### Phase 3: Generate the Capacitor Plugin

You **MUST invoke** the `capacitor-plugin-generator` skill via the Skill tool in
structured mode, passing the confirmed API spec — announce it first (`Invoking
capacitor-plugin-generator in structured mode (Phase 3)…`) and surface its
scaffold result. Do **not** hand-roll the scaffold, the TypeScript contract, the
web layer, or the native bridges yourself, and do **not** substitute reading the
generator's `references/` files for invoking it. Running the bare
`npm init @capacitor/plugin` CLI yourself is also not a substitute — the skill
owns that step plus the contract-first generation playbook around it.

The generator handles scaffolding (package.json, podspec, tsconfig,
build.gradle). Then apply the following on top of the generator output:

- OutSystems naming conventions from `references/unified-structure.md`.
- OutSystems error code format from `references/unified-structure.md` — generate
  an error enum (e.g. `CameraError`) with every error case using the
  `OS-PLUG-<PLUGIN>-NNNN` format, and ensure every `call.reject()` passes one of
  these codes.
- OSS-clean rule: no OutSystems types, no Cordova bridge code — except error codes.
- **SPM-primary iOS dependencies** from the "iOS Dependencies — SPM-primary"
  section of `references/unified-structure.md` — when a dependency ships an SPM
  distribution, declare it under `dependencies.ios.spm` and wire it into
  `Package.swift`, with the podspec as the CocoaPods fallback (ship both). Go
  CocoaPods-only only when no SPM distribution exists. Note: a Cordova
  `<pod … nospm="true">` marker means SPM already satisfies that dep — port it
  SPM-primary, do **not** read it as "keep CocoaPods".
- **Platform gotchas** from the "Platform Gotchas" section of
  `references/unified-structure.md` — apply the iOS/Android correctness rules
  (FileProvider subclassing, Kotlin error-enum exception wrapper, Swift
  `public`/`internal` visibility, Android PhotoPicker for gallery selection,
  window-insets handling for full-screen Activities) to the generator's output.
  These are the defect classes that the Phase 6 native build catches; applying
  them up front avoids the rework.

Then generate **full native implementations** for both iOS and Android — not
stubs. The output must be working code a developer can build and run:

- `src/definitions.ts` — complete TypeScript contract derived from the agreed spec.
- `src/web.ts` — web stubs (native-only methods throw `unimplemented()`).
- `android/.../` — complete Kotlin implementation: bridge delegates to impl class,
  impl class contains real business logic using Android SDK APIs.
- `ios/Plugin/` — complete Swift implementation: bridge delegates to impl class,
  impl class contains real business logic using iOS SDK APIs.

When an existing plugin (Cordova or Capacitor) covers the same functionality, use
its native implementation as the authoritative reference and port it to the target
platform's conventions. Do not guess at business logic when a working implementation
already exists.

### Phase 4: Generate the Cordova Plugin

Read `references/cordova-generation.md`. Also apply the "Platform Gotchas"
checklist in `references/unified-structure.md` to the Cordova native code (the
same iOS/Android correctness rules applied to the Capacitor side in Phase 3 —
FileProvider subclassing, Kotlin error-enum wrapper, Swift visibility, Android
PhotoPicker, window insets). Generate `cordova-outsystems-{plugin}/` with **full
native implementations** — not stubs. The goal is output that compiles and runs
after `cordova plugin add` with no manual edits; treat that as a target the
Phase 6 native build must confirm, not an assumption (the build is what proves
it):

- `plugin.xml` — feature names, **every** source-file declaration (bridge + impl +
  all helpers), all permissions, all Info.plist entries, all Android Activity
  declarations, and all build dependency declarations.
- `www/js/{plugin}.js` — JS bridge, one exported function per method.
- `src/android/OS{Plugin}Plugin.kt` — CordovaPlugin bridge (thin, delegates to
  impl).
- `src/android/{Plugin}.kt` — complete business logic, no Cordova imports.
- `src/android/{Helper}.kt` — all helper/manager/model files needed by the impl.
- `src/ios/OS{Plugin}Plugin.swift` — CDVPlugin bridge (thin, delegates to impl).
- `src/ios/{Plugin}.swift` — complete business logic, no Cordova or Capacitor
  imports.
- `src/ios/{Helper}.swift` — all helper/manager/model/extension files.
- `package.json`, `README.md`.

Every option in every method's options object must be read and applied in native
code — not just parsed into a struct and then ignored.

When an existing plugin covers the same functionality, read its native source and
port it rather than generating from scratch. The Cordova plugin's implementation
is the primary reference for camera, gallery, video, and editing logic.

### Phase 5: Verify API Parity

Read `references/api-parity.md`. Verify that method names, option keys, return
shapes, permission model, and action name strings match exactly between both
plugins. Flag any discrepancy before proceeding.

### Phase 6: Native Build Verification

Read `references/build-verification.md`. **API parity (Phase 5) is static — it
does not prove the native code compiles.** Before declaring the plugins
build-ready, verify each one with a real native build in a throwaway consuming
app, per the procedure in that reference:

- For each generated plugin, scaffold a minimal **consuming Capacitor app**
  (Capacitor-consuming-Capacitor for `capacitor-{plugin}`; Capacitor-consuming-
  Cordova for `cordova-outsystems-{plugin}`) with a **required testable
  `www/index.html`** — one button per method plus a result panel — generated
  from the agreed API spec (template in `references/build-verification.md`).
  Never leave the app as a bare stub: it is what the developer uses for the
  device pass. Then `npm install` the local plugin, `npx cap add` the target
  platforms, inject the plugin's required `Info.plist` usage strings into the
  app, and run `assembleDebug` (Android) and `xcodebuild` (iOS simulator, no
  signing).
- Fix any compile/manifest-merge failures in the generated plugin and rebuild
  until green. The defect classes this catches map to the Error Handling table
  (FileProvider collision, Kotlin enum-as-`Throwable`, Swift visibility, etc.).
- **Degrade gracefully:** run whatever the environment supports. If Xcode or the
  Android SDK is missing, run the builds that are available and **explicitly
  record which platforms were build-verified vs skipped** in the Phase 7 summary.
  Never silently claim "build-ready" for a platform you did not build.
- A passing native build is **build verification**, not device verification.
  Behavioral correctness (camera capture, gallery UX, editor rendering, video
  playback) still requires a device pass — flag it as outstanding in the summary.
  This gap matters most when the plugin reimplements a complex native library
  OSS-clean: it can compile cleanly yet still misbehave at runtime.

### Phase 7: Output Summary

Output a tree view of both generated directories, the detected scenario, source
of the API spec, a "How they relate" note (same API, generated from same spec,
no shared runtime code), and the **Phase 6 build-verification results** (which
platforms built, what was skipped, and any remaining device-verification work).
This completes the high-code phase. Note that OML / ODC binding generation is a
separate phase-2 effort (see Phase 8) and is not performed here.

### Phase 8: OutSystems Plugin (OML) / ODC Bindings — Phase 2 (not yet implemented)

**Deferred. Do not run this from the current skill.** Generating the OutSystems
Plugin (Mobile Library OML) and ODC bindings is a separate, later phase. When
authored, this phase will **invoke the `odc-bindings-generator` skill** —
consistent with the orchestrator model: the unifier delegates to specialist
skills rather than generating bindings inline.

`references/oml-generation.md` is retained as **reference material for that
future phase** (Extensibility Configurations JSON, Structures and Static
Entities, Licenses Block, client actions, UI blocks); it does not authorize
inline OML generation in the current high-code phase.

## Best Practices

### DO

- ✅ Read `references/scenario-detection.md` first, every time, before
  inspecting any source or proposing any API.
- ✅ Agree the full API spec with the user before writing a single file.
- ✅ Invoke the specialist skills via the Skill tool — `cordova-plugin-migrator`
  whenever a Cordova plugin exists (Scenario 2/3), and `capacitor-plugin-generator`
  in structured mode for the Capacitor side (Phase 3). Announce each invocation
  and surface the artifact it returns. Do not re-implement their work inline.
- ✅ Keep bridge files thin on both sides. Business logic goes in the impl
  class (`{Plugin}.kt`, `{Plugin}.swift`) with no framework imports.
- ✅ When the real implementation lives in a separate native library, ask the
  developer for its source repos and **port/copy it** rather than reimplementing
  from scratch. Owned code ports freely; open-source code is fine to copy when
  license-compliant. "OSS-clean" constrains the *result* (no OutSystems/Cordova
  namespaces, no separate-lib dependency), not whether you may copy. If access
  is refused, reimplement and flag the fidelity gap — don't block.
- ✅ Verify API parity between both plugins before declaring Phase 1 complete.
- ✅ **Verify each plugin with a real native build (Phase 6) before claiming
  "build-ready"** — a consuming-app `assembleDebug` + `xcodebuild`, not just the
  TypeScript build and a static parity check. Build verification ≠ device
  verification; call out remaining device-verification work explicitly.
- ✅ Surface every conflict in Scenario 3 explicitly — never auto-resolve.
- ✅ Aim for both plugins to be **build-ready**: every source file declared in
  `plugin.xml`, every Activity registered in AndroidManifest, every option field
  parsed AND applied in native code, all build dependencies declared, and the
  "Platform Gotchas" checklist applied. Treat "installs and runs without manual
  edits" as the **goal the Phase 6 build must confirm**, not an assumption — the
  build is what proves it.
- ✅ Keep the Capacitor plugin OSS-clean: no OutSystems namespaces, no
  Cordova bridge code, no OML references.

### DON'T

- ❌ Hand-roll work that belongs to a sub-skill. Do not analyze Cordova source
  yourself when `cordova-plugin-migrator` applies, and do not scaffold/design/
  write the Capacitor plugin yourself instead of invoking
  `capacitor-plugin-generator`. Reading a sub-skill's `references/` and applying
  them inline is **not** a substitute for invoking it via the Skill tool.
- ❌ Invoke a sub-skill without announcing it first and without surfacing the
  artifact it returns (migrator YAML / generator scaffold result).
- ❌ Proceed to code generation without explicit user confirmation of the
  agreed API spec.
- ❌ Start Phase 2 (OML) without explicit user sign-off on Phase 1 output.
- ❌ Leave a Phase 6 consuming app as a bare stub. Its `www/index.html` must
  have a button per method and a result panel so the developer can run the
  device pass — generate it from the agreed spec
  (`references/build-verification.md`).
- ❌ Re-implement scaffolding that `capacitor-plugin-generator` already handles
  (package.json, podspec, build.gradle, tsconfig).
- ❌ Generate stub implementations. Native business logic must be fully
  implemented — if an existing plugin covers the same functionality, port it.
- ❌ Include OutSystems-specific types, classes, or packages in the Capacitor
  plugin (except error codes following the `OS-PLUG-<PLUGIN>` pattern).
- ❌ Hard-code version targets in the Capacitor plugin — the CLI scaffold sets
  correct targets for the current Capacitor major version.
- ❌ Share native library repos between the two plugins unless the library has
  independent third-party distribution value, or the developer explicitly
  requests one.

## Error Handling

| Symptom | Fix |
| --- | --- |
| Tempted to read `plugin.xml`/JS/native source yourself in Scenario 2/3 | Stop. Invoke `cordova-plugin-migrator` via the Skill tool instead — analyzing the source inline is prohibited. The migrator owns extraction. |
| Tempted to run `npm init @capacitor/plugin` or write `definitions.ts`/bridges yourself in Phase 3 | Stop. Invoke `capacitor-plugin-generator` via the Skill tool in structured mode. Driving the CLI or writing the contract yourself is not a substitute. |
| A required sub-skill is not available in the environment | Stop and tell the user the skill is missing; ask how to proceed. Do not silently fall back to doing its work inline. |
| The existing plugin's bridge just delegates to a separate native library (vendored AAR / `.xcframework` / pod) — the real logic isn't in the cloned repo | Ask the developer for access to that library's Android and iOS source repos and port from them. If refused/unavailable, reimplement from the contract + migrator analysis + SDK patterns and flag the behavioral-fidelity gap for the device pass. See "Sourcing Business Logic from Native Libraries" in `references/unified-structure.md`. |
| Unsure whether copying source is allowed | Owned code ports/copies freely; open-source copies fine when license-compliant (keep attribution, honour copyleft/compatibility). "OSS-clean" forbids OutSystems/Cordova namespaces and separate-lib dependencies, not copying. |
| Scenario 3: APIs look identical but behavior differs | Check action name strings and option key casing — the most common silent mismatches. |
| `cordova-plugin-migrator` returns blockers | Present blockers to the user. Decide whether to proceed with a reduced API surface or halt. |
| `capacitor-plugin-generator` rejects the spec | Re-validate against `capacitor-plugin-generator/references/input-contract.md` before retrying. |
| Action name in `www/js/{plugin}.js` doesn't match Android `execute()` or iOS selector | Action names must be identical across the JS bridge, `execute()` `when` branches, and `@objc(actionName:)` selectors. |
| Both plugins generated but OML JS node returns undefined | Verify the Cordova bridge function name matches `cordova.plugins.{Plugin}.methodName` and the Capacitor plugin is registered as `window.CapacitorPlugins.{Plugin}`. |
| Cordova plugin not found at runtime | Verify the `<feature>` name in `plugin.xml` matches `PLUGIN_NAME` in `www/js/{plugin}.js` and the class annotation in the native bridge. |
| Capacitor plugin generator produces non-OutSystems naming | Apply naming conventions from `references/unified-structure.md` after the generator runs. |
| Declared "build-ready" but never ran a native build | Run Phase 6. Static parity + a TypeScript build do **not** prove the native code compiles. Build each plugin in a consuming app (`assembleDebug` + `xcodebuild`) before claiming build-ready. |
| Android manifest merge fails on `FileProvider` (`authorities`/`name` collision) | The plugin declared a bare `androidx.core.content.FileProvider`, colliding with the host app's. Subclass it (`<Plugin>FileProvider : FileProvider()`) and reference the subclass in the manifest. See "Platform Gotchas" in `references/unified-structure.md`. |
| Kotlin: "type mismatch: inferred type is `<Error>` but `Throwable` was expected" | The error enum is being `throw`n. Kotlin enums can't be `Throwable` (Swift `enum: Error` can). Wrap it: `class <Plugin>Exception(val error: <Plugin>Error) : Exception(error.message)`. |
| Swift/SPM: "method cannot be declared public because its parameter uses an internal type" | A `public` bridge/impl method exposes an `internal` option/result struct. Mark the shared option/result types `public`. |
| Defaulted an iOS dependency to CocoaPods, or read a Cordova `<pod … nospm="true">` as "keep CocoaPods" | Wrong default. SPM is primary on Capacitor 8; declare deps with an SPM distribution under `dependencies.ios.spm` and ship the podspec as fallback. `nospm="true"` means SPM already satisfies that dep — port it SPM-primary. See "iOS Dependencies — SPM-primary" in `references/unified-structure.md`. |
| Android gallery picker is a poor UX / does nothing on API 33+ | Use the PhotoPicker API (`ActivityResultContracts.PickVisualMedia` / `ACTION_PICK_IMAGES`), not `ACTION_GET_CONTENT`, and don't gate it on storage permissions. See "Platform Gotchas". |
| Android full-screen Activity (e.g. image editor) has controls cropped under the system bars | Edge-to-edge is enforced on SDK 35+. Apply `WindowInsetsCompat` padding to the Activity root. See "Platform Gotchas". |
| iOS verification app crashes on first camera/photo access | The consuming app is missing the `NS*UsageDescription` Info.plist strings. Phase 6 must inject the plugin's required usage strings into the verification app before building/running. |

## Related Skills

- `capacitor-plugin-generator`: Generates the Capacitor plugin side in Phase 3.
  Required downstream dependency. Input contract at
  `capacitor-plugin-generator/references/input-contract.md`.
- `cordova-plugin-migrator`: Analyzes an existing Cordova plugin and extracts
  the API surface. Required for Scenario 2 (Cordova exists) and Scenario 3
  (both diverged).
- `odc-bindings-generator` *(phase 2 — not yet implemented)*: Will generate the
  OutSystems Plugin OML / ODC bindings when the phase-2 effort lands. The
  unifier will invoke it (rather than generating bindings inline). Not a
  dependency of the current high-code phase.

## References

- `references/scenario-detection.md`: The three generation scenarios, API spec
  confirmation format, and conflict resolution procedure for Scenario 3.
- `references/unified-structure.md`: Directory structures, naming conventions,
  OSS-clean rule, sourcing business logic from native libraries (asking for
  library source + porting/licensing), version targets, and the
  bridge/implementation separation rule.
- `references/cordova-generation.md`: Full Cordova plugin generation rules and
  file templates (plugin.xml, www/js/, Android KT, iOS Swift).
- `references/api-parity.md`: API parity rules enforced across both plugins.
- `references/build-verification.md`: Phase 6 — consuming-app native build
  verification per platform (scaffold, `cap add`, Info.plist injection,
  `assembleDebug` / `xcodebuild`, graceful degradation, what to record).
- `references/oml-generation.md`: Phase 2 — Extensibility Configurations JSON,
  Structures, Static Entities, Licenses Block, client actions, and UI blocks.
