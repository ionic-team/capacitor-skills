# Audit Patterns

Run these before proposing any edit. Scan the app's `ios/` tree
(excluding `Pods/`, `build/`, `DerivedData/`, `.build/`) and installed
plugin sources under `node_modules/@capacitor*` plus any local plugin
paths from `package.json`.

The CLI migrator's own scan warns on `tmpWindow`, `TmpViewController`,
`UIApplication.shared.applicationState`, and custom `open:`/`continue:`
bodies; the remaining checks are this skill's own.

## Blocks the 8.5 build

| Pattern | Meaning | Remedy |
|---|---|---|
| `\btmpWindow\b` | Removed from `CapacitorBridge` in 8.5 | Delete. If the code presented UI from it, present from `bridge.viewController`; other uses have no 8.5 replacement, so ask what the code intended |
| `\bTmpViewController\b` | Removed in 8.5 | Delete the reference |

```bash
rg -n --type swift -e '\btmpWindow\b' -e '\bTmpViewController\b' ios \
  -g '!**/Pods/**' -g '!**/build/**' -g '!**/DerivedData/**'
```

## Needs a decision (Phase 6)

| Pattern | Meaning |
|---|---|
| `func application\([^)]*\bopen url:` with a body beyond `return ApplicationDelegateProxy.shared.application(...)` | Custom deep-link logic that stops running under scenes; must move to `scene(_:openURLContexts:)` |
| `func application\([^)]*\bcontinue userActivity:` with a custom body | Same, for universal links; moves to `scene(_:continue:)` |
| `applicationDidBecomeActive\|applicationWillResignActive\|applicationDidEnterBackground\|applicationWillEnterForeground` with non-empty bodies in `AppDelegate.swift` (comment-only counts as empty) | AppDelegate lifecycle methods stop being called under scenes; move code to the SceneDelegate equivalents or observe the `UIApplication` notifications (which still fire) |
| Existing `SceneDelegate.swift` | Inventory its methods; merge, never replace |
| Existing `UIApplicationSceneManifest` in `Info.plist` | Compare against the template manifest; merge missing keys only |
| Custom class on the storyboard's bridge view controller (`customClass=` in `Main.storyboard` on the CAPBridgeViewController scene) | Must be carried into the SceneDelegate's `rootViewController` line. If the plist references a storyboard that is missing from disk, note it and skip this check |

A forwarder-only body is not custom. This is the same test the CLI
uses: strip the `ApplicationDelegateProxy` call and comments; if
nothing meaningful remains, the method is template-shaped.

## Informational (report, do not edit)

| Pattern | Meaning |
|---|---|
| `UIApplication.shared.applicationState` | Still works in a single-scene app. Note it; scene-scoped code should prefer the window scene's `activationState` |
| `NotificationCenter` observers for `capacitorOpenURL` / `capacitorOpenUniversalLink` / `CDVPluginHandleOpenURL` | Keep working on 8.5; the scene path re-posts them with the same payload |
| `.capacitorSceneOpenURL` / `.capacitorSceneWillConnect` / `.capacitorSceneOpenUniversalLink` usage in a plugin | Only posted on 8.5+; flag if the plugin also targets 8.4 |

Findings inside `node_modules` belong to the plugin's upstream. Report
them with the plugin name and version; never edit vendored code.
