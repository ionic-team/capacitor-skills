# iOS Guide

Use Swift for generated iOS code unless the user explicitly asks otherwise.
Keep the Capacitor plugin class thin and delegate native work to an
implementation class.

## Bridge Shape

```swift
import Foundation
import Capacitor

@objc(ExamplePlugin)
public class ExamplePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "ExamplePlugin"
    public let jsName = "Example"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "getSignal", returnType: CAPPluginReturnPromise)
    ]

    private let implementation = Example()

    @objc func getSignal(_ call: CAPPluginCall) {
        guard let source = call.getString("source") else {
            call.reject("source is required")
            return
        }

        do {
            let level = try implementation.getSignal(source: source)
            call.resolve(["level": level])
        } catch {
            call.reject(error.localizedDescription)
        }
    }
}
```

```swift
import Foundation

@objc public class Example: NSObject {
    @objc public func getSignal(source: String) throws -> Int {
        return 100
    }
}
```

## Rules

- `jsName` must match `registerPlugin()` and Android
  `@CapacitorPlugin(name)`.
- Every callable bridge method must be `@objc` and listed in `pluginMethods`.
- Parse `CAPPluginCall` values in the plugin bridge class.
- Keep platform logic in the implementation class or facade.
- Keep imports minimal; include only frameworks and native SDKs used by the file.
- Use `call.resolve()`, `call.reject()`, `call.unavailable()`, or
  `call.unimplemented()` consistently with TypeScript/web behavior.
- Use `notifyListeners("eventName", data: payload)` for events.
- Add `override public func load()` only for plugin startup wiring such as
  native observers or managers; keep business logic out of `load()`.

## Permissions

If the plugin needs iOS permissions:

- Add `checkPermissions()` and `requestPermissions()` to the TypeScript API.
- Implement `@objc override public func checkPermissions(_ call:
  CAPPluginCall)` and `@objc override public func requestPermissions(_ call:
  CAPPluginCall)` when iOS needs custom permission handling.
- Map platform states to Capacitor permission states: `granted`, `denied`,
  `prompt`, and `prompt-with-rationale` when applicable.
- Document required `Info.plist` keys in generated README guidance.
- Avoid requesting permissions inside unrelated methods unless the platform API
  requires it; prefer explicit `requestPermissions()`.

If iOS does not require permission for a capability that Android does, still
implement the permission API when the TypeScript contract includes it and return
`granted` on iOS. This keeps the cross-platform API predictable.

## Brightness Pattern

For screen brightness generation:

- Use `UIScreen.main.brightness` on the main thread.
- Clamp input values to `0.0...1.0`.
- Store the original brightness before the first change when the API includes a
  restore method.
- iOS does not expose a separate programmatic brightness mode; return
  `unknown` or reject unsupported mode setters when the API includes system mode
  methods.
- No iOS runtime permission is required for this API, but generated docs should
  explain persistence/lifecycle behavior.

## Dependencies

- Update both the generated podspec and `Package.swift` when a dependency,
  system framework, or entitlement affects both distribution modes.
- Keep package declarations consistent with the plugin's Capacitor version.

## Verification

Run:

```bash
npm run verify:ios
```

If dependency resolution fails, run:

```bash
cd ios
pod install --repo-update
```

Then rerun the verify command from the plugin root.
