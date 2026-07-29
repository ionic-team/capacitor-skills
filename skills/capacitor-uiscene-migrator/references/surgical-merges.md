# Surgical Merges

Recipes for the partial and hand-rolled states the CLI refuses. Each
recipe adds only what is missing and preserves everything the developer
wrote. Show the diff and get confirmation before applying any of them.

## 1. Insert `configurationForConnecting` into an existing AppDelegate

Insert the scene hook (see scene-delegate-template.md) immediately
before the closing brace of the `AppDelegate` class, after the last
existing method. Do not reorder, reformat, or remove anything else.

Idempotency check first: if the file already contains
`UISceneConfiguration(name:`, the hook exists; skip.

If the class ends in nested types or extensions, anchor on the brace
that closes `class AppDelegate`, not the last brace in the file.

## 2. Merge into an existing `UIApplicationSceneManifest`

Never replace the dictionary. Add only missing keys:

- `UIApplicationSupportsMultipleScenes` absent → add as `false`. Present
  as `true` → leave it, and warn: Capacitor 8.5 supports single-window
  only; multi-scene behavior is untested.
- `UISceneConfigurations` / `UIWindowSceneSessionRoleApplication`
  absent → add the template's single configuration.
- A configuration entry exists but lacks `UISceneDelegateClassName` →
  add `$(PRODUCT_MODULE_NAME).SceneDelegate`. If it names a different
  delegate class, that class is the merge target for recipe 3; do not
  repoint the manifest.
- For template parity, also add `UISceneStoryboardFile` = `Main` when
  the app has a `Main.storyboard` on disk; skip the key when it does
  not.
- Preserve the existing `UISceneConfigurationName`. If it is not
  `"Default Configuration"`, use the existing name in the
  `configurationForConnecting` hook so the two agree.

Edit the plist as XML respecting its structure (or PlistBuddy); no
regex string substitution on nested dicts.

## 3. Add missing forwarders to an existing SceneDelegate

Inventory which of the three scene methods exist, then:

- Method missing entirely → add it containing only the
  `SceneDelegateProxy.shared` forwarder.
- Method exists without the forwarder → add the forwarder call,
  preserving the developer's code. In `willConnectTo`, place the
  forwarder after any window setup; in `openURLContexts` and
  `continue`, placement relative to custom code is the developer's
  call. Ask if the custom logic consumes the same URL.
- Delegate creates no window and no storyboard is wired to the scene
  config → add the window setup from the template (this is the
  black-screen case).

## 4. Register a new file in `project.pbxproj`

Preferred: the developer adds `SceneDelegate.swift` to the App target
in Xcode, which writes all four entries correctly. If editing directly,
a new file needs a `PBXBuildFile` entry, a `PBXFileReference`, a child
entry in the App `PBXGroup`, and a line in the target's Sources build
phase, each with a unique 24-hex-character ID. Validate afterwards by
opening the project or running a build; a malformed pbxproj fails
loudly. If it breaks, revert this file only and use Xcode.

## 5. Moving a custom `application(_:open:)` body

When the developer opts for assisted migration (Phase 6, decision 2):

1. Copy the custom logic into `scene(_:openURLContexts:)`, adapting the
   signature: each `UIOpenURLContext` provides `.url` and `.options`.
2. Keep the `SceneDelegateProxy.shared` forwarder in place; the custom
   logic runs alongside it, same as it ran alongside the
   `ApplicationDelegateProxy` forwarder before.
3. Leave the old AppDelegate method in place until the developer's
   keep-or-remove decision from Phase 6, decision 1; under scenes it no
   longer runs either way.
4. `application(_:continue:)` bodies move to `scene(_:continue:)` the
   same way; the `NSUserActivity` parameter carries over unchanged.
