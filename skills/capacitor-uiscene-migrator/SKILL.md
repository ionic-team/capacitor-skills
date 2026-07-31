---
name: capacitor-uiscene-migrator
description: >-
  Assists Capacitor developers migrating an iOS app or plugin from 8.4 to
  the 8.5 UIScene lifecycle, covering what `npx cap migrate` skips or only
  warns about: partially migrated projects, hand-rolled scene delegates,
  and custom application(_:open:) bodies that must move by hand. Audits
  first, reports findings, asks the developer at judgement points, merges
  surgically instead of overwriting, and hands off to `npx cap migrate`
  when the project matches the template shape. Branches for Capacitor
  plugin repos, auditing Swift for lifecycle assumptions without touching
  app-level files. Use when the user says "migrate my Capacitor app to
  UIScene", "add SceneDelegate support", "Capacitor 8.5 migration",
  "update to Capacitor 8.5", "adopt the scene lifecycle", "Xcode 27
  Capacitor build failing", or mentions the "CLIENT OF UIKIT REQUIRES
  UPDATE" warning. Do not use for Cordova-to-Capacitor migration (use
  cordova-plugin-migrator), generating new plugins
  (use capacitor-plugin-generator), or Capacitor 9 migrations.
metadata:
  author: ionic
  source: https://github.com/ionic-team/capacitor-skills
---

# Capacitor UIScene Migrator

Guides a Capacitor 8.4 → 8.5 iOS migration to the UIScene lifecycle. The
CLI migrator (`npx cap migrate`) handles projects that still match the
Capacitor templates; this skill exists for everything else. It audits
before editing, asks the developer where judgement is required, merges
into existing files rather than replacing them, and delegates the
mechanical work to the CLI whenever the project shape allows.

The canonical migration reference is the
[8.4 → 8.5 migration guide](https://capacitorjs.com/docs/updating/8-5).
Link it whenever a step is left for the developer to do manually.

## When to Use This Skill

- Migrating a Capacitor 8.x iOS app to the UIScene lifecycle
- A project where `npx cap migrate` reported a partial state and skipped
- An app with a hand-rolled `SceneDelegate.swift` or a customized
  `AppDelegate.swift` (deep-link routing, third-party SDK forwarding)
- Auditing a Capacitor plugin repo for UIScene compatibility
- Diagnosing the Xcode "CLIENT OF UIKIT REQUIRES UPDATE: This process
  does not adopt UIScene lifecycle" warning in a Capacitor app

## When NOT to Use This Skill

- Cordova-to-Capacitor plugin migration → `cordova-plugin-migrator`
- Generating a new Capacitor plugin → `capacitor-plugin-generator`
- Capacitor 9 or later migrations (this skill is 8.4 → 8.5 only)
- Android lifecycle work (UIScene is iOS only)
- General Capacitor debugging unrelated to the scene lifecycle

## Prerequisites

- A Capacitor 8.x project (app or plugin) with an `ios/` platform or
  iOS sources
- `@capacitor/cli` 8.5+ available for the `npx cap migrate` handoff
- Xcode installed if the developer wants build verification

## What Changed in 8.5 (facts the audit relies on)

These determine what breaks and what does not. Do not soften them.

- Scene adoption is opt-in. An app with no `UIApplicationSceneManifest`
  keeps the AppDelegate path, which still works on the 8.5 core. iOS
  posts `UIScene.*` notifications even for legacy apps (compatibility
  scene), so the bridge's JS `resume`/`pause` events fire in both modes.
- Once the scene manifest exists, iOS stops calling
  `application(_:open:options:)`, `application(_:continue:)`, and the
  four foreground/background AppDelegate methods
  (`applicationDidBecomeActive`, `applicationWillResignActive`,
  `applicationDidEnterBackground`, `applicationWillEnterForeground`).
  Custom code in any of those silently stops running. The
  `UIApplication` notifications still fire; `didFinishLaunching`,
  `applicationWillTerminate`, push token registration, and the
  remote-notification callbacks stay on the AppDelegate.
- `SceneDelegateProxy` re-posts the legacy `.capacitorOpenURL`,
  `.capacitorOpenUniversalLink`, and `CDVPluginHandleOpenURL`
  notifications with the same payload shape, so existing observers keep
  working. Cold-start URLs are delivered after the bridge view appears,
  so both `appUrlOpen` and `getLaunchUrl()` work on cold launch.
- New `.capacitorSceneWillConnect`, `.capacitorSceneOpenURL`, and
  `.capacitorSceneOpenUniversalLink` notifications carry the `UIScene`
  as the object. They are only posted on 8.5+; plugins that also support
  8.4 must keep using the legacy names.
- `TmpViewController` and `CapacitorBridge.tmpWindow` were removed. Any
  reference is a build error on 8.5.
- The 8.5 templates create the window in code in
  `scene(_:willConnectTo:)`; `Main.storyboard` no longer provides the
  root view controller. Custom `CAPBridgeViewController` subclasses are
  instantiated in the SceneDelegate, not set in the storyboard.

## Agent Behavior

- Audit first, report second, edit last. Never modify a file before the
  developer has seen the findings and confirmed.
- Never overwrite an existing `SceneDelegate.swift`, `AppDelegate.swift`,
  or `Info.plist` structure. Merge surgically per
  [references/surgical-merges.md](references/surgical-merges.md).
- Prefer the CLI. If the project classifies as eligible (Phase 3), run
  `npx cap migrate` instead of editing files by hand.
- Ask, do not assume, at the decision points in Phase 6. Use
  `AskUserQuestion` where available; otherwise ask in plain text and
  wait.
- Do not commit, stage, or push. Leave version control to the developer.
- On a plugin repo, never touch `Info.plist`, `AppDelegate.swift`, or
  project files. The plugin branch is audit and advice only.

## Procedures

### Phase 1: Detect Repo Type

Decide app vs. plugin before anything else.

- **App**: has `ios/App/App.xcodeproj` (or `capacitor.config.*` with an
  `ios/` platform directory).
- **Plugin**: has a `Package.swift` or `.podspec` depending on
  Capacitor, `CAPPlugin`/`CapacitorPlugin` subclasses in `ios/Sources`
  or `ios/Plugin`, and no `App/App.xcodeproj`.

Plugin repo → skip to Phase 10
([references/plugin-repo-audit.md](references/plugin-repo-audit.md)).

### Phase 2: Detect Package Manager and Versions

- Pods vs. SPM: `ios/App/Podfile` → CocoaPods; `Package.swift` or an SPM
  reference inside the Xcode project → SPM. This affects how `npx cap
  sync ios` behaves, not the SceneDelegate content: the 8.5 templates
  ship one SceneDelegate for both.
- Check `@capacitor/ios` version in `package.json`. If below 8.5, the
  dependency update is part of the migration; the CLI migrator handles
  it, or update manually per the guide.

### Phase 3: Classify the Project State

Read the same three signals the CLI migrator uses:

1. `Info.plist` contains `UIApplicationSceneManifest`
2. `SceneDelegate.swift` exists on disk in the app target directory
   (pbxproj registration is a separate concern, handled in Phase 7)
3. `AppDelegate.swift` contains `UISceneConfiguration(name:`

| Signals present | State | Route |
|---|---|---|
| 0 of 3 | eligible | Phases 4-6, then Phase 7a: hand off to `npx cap migrate` |
| 3 of 3 | already migrated | Audit only (Phase 4), then verify (Phase 9) |
| 1-2 of 3 | partial | Phases 4-6, then Phase 7b: surgical merges |

Every route audits before anything runs or changes; the routes differ
only in who applies the changes.

The CLI warns and skips on partial states by design. Partial is exactly
where this skill does its own editing.

### Phase 4: Audit the Codebase

Run the scans in
[references/audit-patterns.md](references/audit-patterns.md) across the
app's iOS sources and installed plugins (`node_modules/@capacitor*`,
plus any local plugin paths). Collect findings for:

- `UIApplication.shared.applicationState` usage
- Custom `application(_:open:)` / `application(_:continue:)` bodies
  beyond the `ApplicationDelegateProxy` forwarder
- Custom code in AppDelegate lifecycle methods
- Existing `SceneDelegate.swift` implementations and what they contain
- References to `tmpWindow` / `TmpViewController` (build errors on 8.5)
- Existing or partial `UIApplicationSceneManifest` entries
- `.capacitorOpenURL` / `.capacitorOpenUniversalLink` observers
  (informational: they keep working)

### Phase 5: Present Findings and Confirm

Report every finding with file and line before touching anything.
Group as: blocks the build (tmpWindow/TmpViewController), needs a
decision (custom delegate bodies, existing SceneDelegate), informational
(observers, applicationState in plugins the developer does not own).
Ask the developer to confirm proceeding.

### Phase 6: Decision Points

Ask, at minimum:

1. **Legacy URL handlers**: keep or remove
   `application(_:open:options:)` / `application(_:continue:)` in
   `AppDelegate.swift`? They become dead code under scenes. Keeping them
   is harmless; removing them is cleaner. If the body contains custom
   logic, it must move to the SceneDelegate either way. On the eligible
   route, apply the answer after the CLI has run.
2. **Custom `application(_:open:)` body**: migrate it manually (the
   developer moves the logic) or have the skill move it into
   `scene(_:openURLContexts:)` alongside the proxy forwarder? Show the
   body before asking. Skip this question when the body is
   forwarder-only per the audit test.
3. **Existing SceneDelegate**: confirm each proposed insertion
   (missing forwarders, window setup) as a diff before applying.

### Phase 7a: Eligible → CLI Handoff

Verify the resolved CLI first: run `npm install` if `node_modules` is
missing, then `npx cap --version`; the UIScene migrator needs 8.5 or
newer. Then run `npx cap migrate` and interpret its output. It writes
`SceneDelegate.swift`, patches `Info.plist` and `AppDelegate.swift`,
registers the file in `project.pbxproj`, warns on the scan patterns from
Phase 4, and links the migration guide. Confirm each step's log line;
if the CLI skipped a step (file existed, partial state raced in),
fall through to Phase 7b for that step only.

### Phase 7b: Partial or Hand-Rolled → Surgical Merges

Apply only the missing pieces, per
[references/surgical-merges.md](references/surgical-merges.md):

- Missing manifest → merge `UIApplicationSceneManifest` into
  `Info.plist`, preserving existing keys
- Missing `configurationForConnecting` → insert into the existing
  `AppDelegate.swift` before the class's closing brace, displacing
  nothing
- Missing or incomplete `SceneDelegate.swift` → create from
  [references/scene-delegate-template.md](references/scene-delegate-template.md),
  or add the missing `SceneDelegateProxy.shared` forwarders to the
  existing one, preserving all custom logic
- New file → register in `project.pbxproj` (Xcode does this when the
  file is added through the IDE; otherwise follow the reference)

### Phase 8: Sync and Build

Run `npx cap sync ios`. If Xcode is available, build the app target and
surface any errors (most commonly leftover `tmpWindow` references).

### Phase 9: Verification Checklist

Walk the developer through, linking the guide for detail:

- App launches to the web view
- Background and foreground the app: JS `resume`/`pause` fire (they are
  scoped to the app's scene now)
- Custom URL scheme: cold launch and warm open both deliver the URL
  (`appUrlOpen` listener and `App.getLaunchUrl()`)
- Universal link, if the app uses them (requires an associated domain)

### Phase 10: Plugin Repo Branch

No app-level files to patch. Audit the plugin's Swift per
[references/plugin-repo-audit.md](references/plugin-repo-audit.md) and
report: lifecycle assumptions that break under scenes, APIs removed in
8.5, and the compatibility rules for supporting 8.4 and 8.5 with one
plugin version. Apply code changes only if the developer asks, and only
in the plugin's own sources.

## Best Practices

### DO

- Show diffs before applying them
- Keep every finding tied to a file and line
- Re-run the Phase 3 classification after edits to confirm the project
  reads as fully migrated
- Tell plugin authors to keep the legacy notification names while they
  support 8.4

### DON'T

- Overwrite user code, ever
- Rewrite third-party plugin code under `node_modules` (report it;
  the fix belongs upstream)
- Duplicate the CLI's work by hand-editing an eligible project
- Promise universal-link behavior without an associated domain to test

## Error Handling

- `npx cap migrate` warns "partial state" → expected; this skill's
  Phase 7b exists for that. Do not reset the project without asking.
- `project.pbxproj` edits fail or the project no longer opens → revert
  the pbxproj change and register the file through Xcode instead.
- Build fails on `tmpWindow` / `TmpViewController` → the references
  must be deleted; there is no 8.5 replacement (the bridge's
  `viewController` is the presentation anchor).
- `SceneDelegate` exists but the app shows a black screen → the
  delegate neither creates a window nor lets a storyboard do it; add
  the window setup from the template.

## Related Skills

- `cordova-plugin-migrator`: Cordova plugin to Capacitor migration
- `capacitor-plugin-generator`: new Capacitor plugin scaffolds

## References

| File | Purpose |
|---|---|
| [references/scene-delegate-template.md](references/scene-delegate-template.md) | The 8.5 SceneDelegate template and custom-subclass variant |
| [references/audit-patterns.md](references/audit-patterns.md) | Exact scan patterns with commands |
| [references/surgical-merges.md](references/surgical-merges.md) | Merge recipes for partial and hand-rolled projects |
| [references/plugin-repo-audit.md](references/plugin-repo-audit.md) | Plugin-author branch: audit and compatibility rules |
