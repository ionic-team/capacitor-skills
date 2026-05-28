# Using `capacitor-plugin-generator`

Phase 11 invokes the `capacitor-plugin-generator` skill via the Skill
tool, passing the structured YAML plan produced in Phase 9. The generator
runs its own playbook (scaffold, TypeScript contract, web, iOS, Android,
sample app, docgen, verify) and returns a candidate Capacitor plugin.
This skill never re-implements what the generator does; it produces the
YAML and orchestrates the call.

## The Contract Is Authoritative

The generator's `references/input-contract.md` defines the shape this skill
must produce. **Do not invent fields. Do not rename existing ones. Do not
emit a partial contract and assume the generator will fill in the rest.**

If you cannot fill a required field, that is a Phase 10 checkpoint — stop and
ask the user. It is not a Phase 11 handoff.

## Required Base Contract

Always emit the base block:

```yaml
plugin:
  name: <kebab-case npm name>
  package_id: <reverse-dns Android package id>
  class_name: <PascalCase, no trailing 'Plugin'>
  description: <one-line description>
  repo_url: <repository URL or POC placeholder>
  author: <author string or POC placeholder>
  license: <SPDX>

platforms: [ios, android, web]

api:
  methods: [...]
  types: [...]
  events: [...]

permissions:
  ios: [...]
  android: [...]

dependencies:
  ios:
    cocoapods: [...]
    spm: [...]
    system_frameworks: [...]
  android:
    gradle: [...]
    maven_repos: [...]
```

Field-by-field rules live in the generator's
`references/input-contract.md`. Read that file before producing YAML.

## Optional `migration:` Block

Append the migration block whenever this skill is the source:

```yaml
migration:
  source: cordova
  complexity: simple | moderate | complex | blocked
  output_mode: side_by_side | in_place
  blockers: []
  warnings: []
  language_modernization:
    ios: { from: objective_c | swift, to: swift }
    android: { from: java | kotlin, to: kotlin }
  source_files:
    ios: [src/ios/Foo.m, src/ios/Foo.h]
    android: [src/android/Foo.java]
    js: [www/foo.js]
  hooks:
    tier_1: []
    tier_2: []
    tier_3: []
  cordova_to_capacitor_map:
    - cordova: "Foo.bar(value, success, error)"   # quote every entry — JS syntax breaks YAML otherwise
      capacitor: "Foo.bar({ value })"
  notes: []
```

### Field rules for the migration block

| Field | Rule |
| --- | --- |
| `source` | Always `cordova` for this skill. |
| `complexity` | One of `simple`, `moderate`, `complex`, `blocked`. See `complexity-assessment.md`. |
| `output_mode` | `side_by_side` by default. `in_place` only on explicit user opt-in. |
| `blockers` | Free-form strings, one per blocker. The generator stops on non-empty. |
| `warnings` | Free-form strings, one per warning. The generator surfaces these but does not stop. |
| `language_modernization.ios.from` | `objective_c` or `swift`. |
| `language_modernization.android.from` | `java` or `kotlin`. |
| `source_files.*` | Paths relative to the Cordova plugin root. Used by the reviewer to diff against the generated output. |
| `hooks.tier_1`, `hooks.tier_2`, `hooks.tier_3` | Arrays of `{ name, src, type, purpose }`. Tier 3 entries are *also* listed in `blockers`. |
| `cordova_to_capacitor_map` | One row per public method. Helps the reviewer trace each generated method back to the Cordova original. |
| `notes` | Free-form. Use for "mirrors `@capacitor/<name>` v<version>" style breadcrumbs. |

## Wire-Format Fidelity When an Equivalent Exists

When an official Capacitor equivalent exists, the migrator's job is largely
to **pin the wire format** so the generator does not re-derive enum casing,
event names, or method names from human-friendly strings.

Read the equivalent's `definitions.ts`. For each enum, listener, method, and
result type, mirror the exact string. Example pattern:

```yaml
api:
  types:
    - name: CameraResultType
      kind: union
      values: [uri, base64, dataUrl]   # exact strings from @capacitor/camera
    - name: CameraSource
      kind: union
      values: [PROMPT, CAMERA, PHOTOS] # exact casing from @capacitor/camera
  events:
    - name: cameraDidChange            # if an event exists, use the exact string
```

Add a `migration.notes` line:

```yaml
migration:
  notes:
    - Mirrors @capacitor/camera v6.x definitions.ts (CameraResultType, CameraSource)
```

The generator skill's "Native Dependency Detection" rule then triggers an
SDK-adapter pattern instead of a reimplementation.

## Phase 11 Invocation

After Phase 10 checkpoint approval, invoke the `capacitor-plugin-generator`
skill via the Skill tool, passing the structured YAML as the input
argument. The generator detects structured-mode input by the presence of
`plugin`, `platforms`, and `api` at the YAML root, skips its own
elicitation phases, and proceeds directly to scaffold + implementation.

### Standard invocation (Simple / Moderate complexity)

For plugins assessed as `simple` or `moderate` (see
`complexity-assessment.md`), invoke the generator **once** with the full
YAML. The generator runs all of its phases end-to-end and returns the
candidate plugin.

### Incremental invocation (Complex)

For plugins assessed as `complex`, invoke the generator **incrementally**
— one platform at a time — with user checkpoints between each call. The
sequence:

1. Invoke generator with `platforms: [web]` plus the TypeScript contract.
   Wait for user inspection and approval.
2. Invoke generator with `platforms: [ios]`. Wait for user inspection.
3. Invoke generator with `platforms: [android]`. Wait for user inspection.
4. Invoke generator with full `platforms: [web, ios, android]` for final
   docgen and verify.

This prevents context overflow on plugins with large native surfaces and
lets the user reject any single platform without rolling back the others.

### Pre-flight checks before invoking

- `migration.blockers` must be empty.
- `migration.hooks.tier_3` must be empty.
- Phase 10 checkpoint was acknowledged by the user.
- YAML passes contract validation against
  `capacitor-plugin-generator/references/input-contract.md`.

If any check fails, do not invoke. Surface the failure and stop.

---

## ODC Path: Invoking `build-actions-generator` Before the Generator

**When it applies:** `odc_target: true` (confirmed in Phase 1).

### Phase 11a — Invoke `build-actions-generator`

- Pass: the Phase 9 YAML (full input-contract shape) and the Cordova plugin
  directory path as the working directory or argument.
- The skill reads the relevant sections (`migration.hooks`, `dependencies`,
  `permissions`, `plugin`) and **always also scans source directly**.
- Output goes to `build-actions/` inside the Capacitor plugin directory:
  - **Mode B:** `<sibling-capacitor-dir>/build-actions/`
  - **Mode A:** `<repo-root>/build-actions/` (after Phase 12 relocation)
- After the skill completes, read `build-actions/README.md` to determine what
  was covered — the actions table ("What this configures") and the unmapped
  items table ("What requires additional setup").

### Determining what the generator should skip

- Any hook in `migration.hooks.tier_1` whose purpose is a config-level
  host-app modification (plist key, AndroidManifest entry, entitlement, Gradle
  dependency) **that was emitted as a build action** should be marked
  `status: handled_by_build_actions` before passing to the generator.
- Hooks that remain (file copies, asset pipelines, non-config scripts) stay
  in `tier_1` as normal.
- Add a `migration.notes` entry:
  `"ODC: config-level host-app modifications are handled by build actions in build-actions/. See build-actions/README.md."` so the generator and reviewer have a clear audit trail.

### Phase 11b — Invoke `capacitor-plugin-generator`

- Pass the annotated YAML (tier_1 hooks with handled ones marked,
  `migration.notes` updated).
- The generator emits Capacitor hooks only for items **not** marked
  `handled_by_build_actions`.
- Standard vs incremental complexity rules apply as before.

### Pre-flight checks for Phase 11a

- Same as existing pre-flights (`migration.blockers` empty,
  `migration.hooks.tier_3` empty, Phase 10 acknowledged).
- Additionally: if `build-actions-generator` is not available, fall back to
  the non-ODC path and document the manual ODC setup steps (build action
  configuration) in `MIGRATION.md`.

---

## What the Generator Will Reject

The generator skill rejects YAML with any of:

1. Missing `plugin.name`, `plugin.package_id`, `plugin.class_name`,
   `plugin.author`, `plugin.license`, or `plugin.repo_url`.
2. Empty `platforms` array.
3. `api.methods` referencing a type that is not declared in `api.types`.
4. `api.events` whose name does not match the wire-format string elsewhere
   in the contract.
5. Non-empty `migration.blockers`.
6. Non-empty `migration.hooks.tier_3`.

Treat each of these as a Phase 9 bug in this skill, not a Phase 11 problem
in the generator. Fix the YAML here before re-invoking the generator.

## Boundary Rules

- The generator owns scaffolding, native code, web layer, sample app,
  docgen, and verify. Do not pre-emit any of those artifacts from this
  skill.
- This skill owns Cordova source analysis. Do not ask the generator to read
  `plugin.xml` or any iOS/Android Cordova source.
- If the generator asks for something the contract does not currently
  capture, the bug is in the contract or in this skill's analysis — not in
  the generator. Update Phase 9 here and re-hand the YAML.
