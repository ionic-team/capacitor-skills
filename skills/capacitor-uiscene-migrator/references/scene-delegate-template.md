# SceneDelegate Template (Capacitor 8.5)

The 8.5 templates ship one `SceneDelegate.swift` for both CocoaPods and
SPM projects. Source of truth: `ios-pods-template/App/App/SceneDelegate.swift`
and `ios-spm-template/App/App/SceneDelegate.swift` in the Capacitor repo
(byte-identical).

```swift
import UIKit
import Capacitor

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = CAPBridgeViewController()
        window?.makeKeyAndVisible()

        SceneDelegateProxy.shared.scene(scene, willConnectTo: session, options: connectionOptions)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        SceneDelegateProxy.shared.scene(scene, openURLContexts: URLContexts)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        SceneDelegateProxy.shared.scene(scene, continue: userActivity)
    }
}
```

Every `SceneDelegateProxy.shared` forwarder is load-bearing:

- `willConnectTo` delivers cold-start URLs and universal links (buffered
  by the core until plugins load, so `appUrlOpen` fires on cold launch)
- `openURLContexts` delivers warm custom-scheme opens
- `continue` delivers warm universal links

## Custom view controller subclass

The delegate creates the root view controller in code; `Main.storyboard`
no longer provides it. A custom `CAPBridgeViewController` subclass is
instantiated here, not set in the storyboard:

```swift
window?.rootViewController = MyViewController()
```

If an existing app set the subclass in `Main.storyboard` (the pre-8.5
customization pattern), moving to this template silently drops the
subclass unless the developer moves it into this line. Always check the
storyboard's custom class during the audit and carry it over.

## AppDelegate scene hook

The matching `AppDelegate.swift` addition:

```swift
func application(_ application: UIApplication,
                 configurationForConnecting connectingSceneSession: UISceneSession,
                 options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    let config = UISceneConfiguration(name: "Default Configuration",
                                      sessionRole: connectingSceneSession.role)
    config.delegateClass = SceneDelegate.self
    return config
}
```

## Info.plist scene manifest

```xml
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <false/>
    <key>UISceneConfigurations</key>
    <dict>
        <key>UIWindowSceneSessionRoleApplication</key>
        <array>
            <dict>
                <key>UISceneConfigurationName</key>
                <string>Default Configuration</string>
                <key>UISceneDelegateClassName</key>
                <string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
                <key>UISceneStoryboardFile</key>
                <string>Main</string>
            </dict>
        </array>
    </dict>
</dict>
```

This matches the shipped templates, including `UISceneStoryboardFile`.
Keep that key when the app has a `Main.storyboard`; skip it when it
does not (surgical-merges recipe 2). Either way, the delegate's window
setup is what puts content on screen.
