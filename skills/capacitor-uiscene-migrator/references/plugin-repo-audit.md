# Plugin Repo Audit

A Capacitor plugin has no `Info.plist`, `AppDelegate`, or scene manifest
to patch. The migration question for a plugin is narrower: does its
Swift make assumptions the scene lifecycle breaks, and can one release
support both 8.4 and 8.5?

## Detection

Treat the repo as a plugin when it has a `Package.swift` or `.podspec`
depending on Capacitor, `CAPPlugin` subclasses under `ios/Sources` or
`ios/Plugin`, and no `App/App.xcodeproj`. An `example-app/` directory
containing an app project does not make it an app repo; audit the
plugin sources, and treat the example app as an app migration only if
the developer asks.

Read the supported Capacitor range first (`peerDependencies` in
`package.json`, the Capacitor dependency in `Package.swift` or the
podspec); the one-plugin-version rule below depends on it.

## What to scan for

| Pattern | Verdict |
|---|---|
| `tmpWindow`, `TmpViewController` | Build error on 8.5. Must be removed. If the code presented UI from it, present from `bridge.viewController`; other uses have no 8.5 replacement, so ask what the code intended |
| Observers for `capacitorOpenURL`, `capacitorOpenUniversalLink`, `CDVPluginHandleOpenURL` | Safe. The 8.5 scene path re-posts all three unchanged: the Capacitor names carry a dictionary (`url`, plus `options` for scheme opens); `CDVPluginHandleOpenURL` carries the `URL` itself |
| Observers for `UIApplication` lifecycle notifications (`didBecomeActive`, `willResignActive`, `didEnterBackground`, `willEnterForeground`) | Safe. These still fire in scene-based apps |
| Overrides or expectations of AppDelegate lifecycle *methods* | Breaks under scenes; iOS calls the scene delegate instead. Move to notification observers |
| `UIApplication.shared.applicationState` | Works in single-window apps. For scene-scoped checks, prefer the view's `window?.windowScene?.activationState` (the pattern Capacitor core uses) |
| `ApplicationDelegateProxy.shared.lastURL` reads | Safe. The scene path mirrors the launch URL into it |
| `.capacitorScene*` notification usage | 8.5-only. A plugin that also supports 8.4 must not depend on these; keep the legacy names |
| Presenting from `UIApplication.shared.keyWindow?.rootViewController` | Works single-window; prefer `bridge.viewController` for correctness and future multi-window |

## The one-plugin-version rule

A plugin that must build and run across Capacitor 8.4 and 8.5 (apps on
either AppDelegate or UIScene):

- Consume the legacy notification names; they are posted on both
- Do not reference removed APIs (`tmpWindow`, `TmpViewController`)
- Do not reference 8.5-only APIs (`SceneDelegateProxy`, the
  `.capacitorScene*` constants); they do not compile against 8.4.
  Observing the equivalent raw-string notification names compiles
  everywhere but never fires on 8.4
- Keep lifecycle handling on `UIApplication` notifications, not
  AppDelegate methods

A plugin meeting all four needs no 8.5-specific release.

## Output

Report findings grouped as: must fix (build errors), should fix
(breaks under scenes), advisory (works but a better pattern exists),
fine as-is. Apply changes only in the plugin's
own sources and only when the developer confirms. Link the
[migration guide](https://capacitorjs.com/docs/updating/8-5) for the
app-side context.
