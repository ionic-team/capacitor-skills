# Cordova Plugin Generation

Rules and templates for generating `cordova-outsystems-{plugin}/`. Apply these
alongside the directory structure in `unified-structure.md`. The Cordova plugin
side is generated directly by `plugin-unifier` — it is not delegated to any
base skill.

> **Also apply the "Platform Gotchas" section of `unified-structure.md`** to the
> Cordova native code — they are the same correctness rules used on the Capacitor
> side and the defects the Phase 6 native build catches: FileProvider must be
> subclassed (not bare), error enums need a Kotlin exception wrapper, gallery
> selection should use the PhotoPicker API (not `ACTION_GET_CONTENT`), full-screen
> Activities must pad for window insets, and iOS usage strings are required. The
> rules below cover the Cordova-specific wiring; the gotchas cover the
> implementation details that make that wiring actually build and run.

---

## `plugin.xml`

Rules:
- `id` = `com.outsystems.plugins.{plugin}` (reverse-domain format).
- Android `<feature>` name = `OS{Plugin}Plugin`, `android-package` =
  `com.outsystems.plugins.{plugin}.OS{Plugin}Plugin`.
- iOS `<feature>` name = `OS{Plugin}Plugin`, `ios-package` = `OS{Plugin}Plugin`.
- `<js-module>` with `src="www/js/{plugin}.js"`, clobbers
  `cordova.plugins.{Plugin}` — always present.
- All required Android permissions declared in `<config-file>` blocks.
- All required iOS `Info.plist` usage description strings declared.
- **Every `.kt` source file** in `src/android/` must have its own `<source-file>`
  entry with the correct `target-dir`. This includes the bridge, the impl class,
  all managers, helpers, models, and any Activity files.
- **Every `.swift` source file** in `src/ios/` must have its own `<source-file>`
  entry. This includes the bridge, impl, managers, helpers, models, and extensions.
- **Every Android Activity** (e.g. editor activities, picker activities) must be
  declared in a `<config-file target="AndroidManifest.xml">` `<activity>` block.
  Full-screen Activities must pad for window insets (see "Platform Gotchas").
- **If the plugin ships a `FileProvider`**, declare a uniquely-named subclass
  (`<Plugin>FileProvider`) — never bare `androidx.core.content.FileProvider`,
  which collides with the host app's provider and fails the manifest merge. Add
  both the `<provider android:name="com.outsystems.plugins.{plugin}.{Plugin}FileProvider" …>`
  entry (under `parent="/manifest/application"`) and a `<source-file>` for the
  `.kt`. See "Platform Gotchas" in `unified-structure.md`.
- **Android build dependencies** (Kotlin coroutines, Gson, AndroidX, etc.) must be
  declared in a standalone `build.gradle` file (see section below) and referenced
  via `<framework src="src/android/build.gradle" custom="true" type="gradleReference"/>`.
  Do not use individual `<framework>` dependency entries in `plugin.xml`.
- **Kotlin must be explicitly enabled** in the Android `<config-file>` block:
  ```xml
  <preference name="GradlePluginKotlinEnabled" value="true"/>
  <preference name="GradlePluginKotlinCodeStyle" value="official"/>
  ```

```xml
<?xml version='1.0' encoding='utf-8'?>
<plugin id="com.outsystems.plugins.{plugin}" version="0.0.1"
  xmlns="http://apache.org/cordova/ns/plugins/1.0"
  xmlns:android="http://schemas.android.com/apk/res/android">

  <name>OS{Plugin}Plugin</name>
  <description>OutSystems Cordova plugin for {Plugin}</description>
  <license>MIT</license>
  <keywords>cordova,outsystems,{plugin}</keywords>

  <js-module name="{Plugin}" src="www/js/{plugin}.js">
    <clobbers target="cordova.plugins.{Plugin}" />
  </js-module>

  <platform name="android">
    <config-file parent="/*" target="res/xml/config.xml">
      <feature name="OS{Plugin}Plugin">
        <param name="android-package"
               value="com.outsystems.plugins.{plugin}.OS{Plugin}Plugin" />
      </feature>
    </config-file>
    <!-- permissions -->
    <source-file src="src/android/OS{Plugin}Plugin.kt"
      target-dir="app/src/main/kotlin/com/outsystems/plugins/{plugin}" />
  </platform>

  <platform name="ios">
    <config-file parent="/*" target="config.xml">
      <feature name="OS{Plugin}Plugin">
        <param name="ios-package" value="OS{Plugin}Plugin" />
      </feature>
    </config-file>
    <!-- Info.plist usage descriptions -->
    <source-file src="src/ios/OS{Plugin}Plugin.swift" />
  </platform>

</plugin>
```

---

## `src/android/build.gradle`

Every Cordova plugin that has Android dependencies must include a `build.gradle`
file at `src/android/build.gradle` and declare it in `plugin.xml` as:

```xml
<framework src="src/android/build.gradle" custom="true" type="gradleReference"/>
```

This is the preferred approach over individual `<framework>` dependency entries
in `plugin.xml`. It keeps all Android build configuration in one place and is
consistent with the OutSystems Cordova plugin convention (see
`cordova-outsystems-barcode` as the reference example).

Template:

```groovy
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.7.2'
    }
}

repositories {
    google()
    mavenCentral()
}

dependencies {
    // Add plugin-specific dependencies here
    implementation 'androidx.appcompat:appcompat:1.7.0'
    implementation 'androidx.activity:activity-ktx:1.9.3'
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm:1.7.3'
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3'
}
```

If the plugin has no Android dependencies beyond the standard SDK (e.g. a
plugin that only uses `ContactsContract`), the `build.gradle` file is not needed.

---

## `www/js/{plugin}.js`

Rules:
- Uses `cordova/exec` for the bridge.
- One exported function per API method.
- Each function calls `exec` with a success callback, failure callback, plugin
  name, action name, and args array.
- `actionName` must exactly match the action string handled in the native bridge
  classes and verified in `api-parity.md`.
- Options objects are passed as-is in the args array.

```javascript
var exec = require('cordova/exec');

module.exports = {
  methodName: function(options, success, failure) {
    exec(success, failure, 'OS{Plugin}Plugin', 'methodName', [options]);
  },
  checkPermissions: function(success, failure) {
    exec(success, failure, 'OS{Plugin}Plugin', 'checkPermissions', []);
  },
  requestPermissions: function(permissions, success, failure) {
    exec(success, failure, 'OS{Plugin}Plugin', 'requestPermissions',
         [permissions || []]);
  }
};
```

---

## `src/android/OS{Plugin}Plugin.kt`

Rules:
- Extends `CordovaPlugin`.
- Override `execute(action: String, args: JSONArray, callbackContext: CallbackContext): Boolean`.
- `when` dispatch on action name — return `true` for known actions, `false` for
  unknown.
- Use `callbackContext.success(result)` or `callbackContext.error(message)`.
- Bridge only — delegate to `{Plugin}.kt` for all business logic. No business
  logic in this class.
- Action names must match exactly what is used in `www/js/{plugin}.js`.

```kotlin
package com.outsystems.plugins.{plugin}

import org.apache.cordova.CordovaPlugin
import org.apache.cordova.CallbackContext
import org.json.JSONArray
import org.json.JSONObject

class OS{Plugin}Plugin : CordovaPlugin() {

    private val implementation = {Plugin}()

    override fun execute(
        action: String,
        args: JSONArray,
        callbackContext: CallbackContext
    ): Boolean {
        return when (action) {
            "methodName" -> {
                methodName(args.optJSONObject(0) ?: JSONObject(), callbackContext)
                true
            }
            "checkPermissions" -> { checkPermissions(callbackContext); true }
            "requestPermissions" -> {
                requestPermissions(args.optJSONArray(0), callbackContext)
                true
            }
            else -> false
        }
    }

    private fun methodName(options: JSONObject, callbackContext: CallbackContext) {
        // delegate to implementation
    }

    private fun checkPermissions(callbackContext: CallbackContext) {
        val result = JSONObject()
        result.put("permissionA", "prompt") // TODO: check actual permission state
        callbackContext.success(result)
    }

    private fun requestPermissions(
        permissions: JSONArray?,
        callbackContext: CallbackContext
    ) {
        // request permissions, then call checkPermissions
        checkPermissions(callbackContext)
    }
}
```

---

## `src/android/{Plugin}.kt`

- Contains the actual business logic.
- **No Cordova imports.** No `CordovaPlugin`, `CallbackContext`, `JSONArray` here.
- Accepts plain Kotlin types. Returns plain Kotlin types or throws standard
  exceptions.
- **Errors:** throw/catch the exception wrapper (not the error enum directly),
  and have the bridge map it back to `callbackContext.error(error.toJson())`.
  See "Platform Gotchas" (Android #2) in `unified-structure.md`.
- **Gallery:** use the PhotoPicker API, not `ACTION_GET_CONTENT`, and don't gate
  it on storage permissions. See "Platform Gotchas" in `unified-structure.md`.

```kotlin
package com.outsystems.plugins.{plugin}

class {Plugin} {
    // business logic methods
}
```

---

## `src/ios/OS{Plugin}Plugin.swift`

Rules:
- `@objc(OS{Plugin}Plugin)` class annotation.
- Extends `CDVPlugin`.
- One `@objc(actionName:)` method per action.
- Send result via `commandDelegate.send(result, callbackId: command.callbackId)`.
- Bridge only — delegate to `{Plugin}.swift` for all business logic.
- Action method names must match exactly what is used in `www/js/{plugin}.js`.

```swift
import Foundation

@objc(OS{Plugin}Plugin)
class OS{Plugin}Plugin: CDVPlugin {

    private let implementation = {Plugin}()

    @objc(methodName:)
    func methodName(_ command: CDVInvokedUrlCommand) {
        let options = command.argument(at: 0) as? [String: Any] ?? [:]
        // delegate to implementation
        let result = CDVPluginResult(status: CDVCommandStatus_ERROR,
                                     messageAs: "not yet implemented")
        commandDelegate.send(result, callbackId: command.callbackId)
    }

    @objc(checkPermissions:)
    func checkPermissions(_ command: CDVInvokedUrlCommand) {
        let response: [String: String] = ["permissionA": "prompt"]
        let result = CDVPluginResult(status: CDVCommandStatus_OK,
                                     messageAs: response)
        commandDelegate.send(result, callbackId: command.callbackId)
    }

    @objc(requestPermissions:)
    func requestPermissions(_ command: CDVInvokedUrlCommand) {
        // request permissions, then send result
        checkPermissions(command)
    }
}
```

---

## `src/ios/{Plugin}.swift`

- Contains the actual business logic.
- **No Cordova imports. No Capacitor imports.**
- Accepts and returns plain Swift types.

```swift
import Foundation

class {Plugin} {
    // business logic methods
}
```

---

## `Package.swift` (iOS — only when the plugin has SPM dependencies)

Generate a Cordova `Package.swift` **only** when the iOS side has SPM
dependencies (the SPM-primary case from `unified-structure.md`, e.g. a Firebase
SDK). Pair it with `<platform name="ios" package="swift">` in `plugin.xml`.
Plugins with no iOS SPM deps must **not** ship one — Capacitor consumes them via
the `capacitor-cordova-ios-plugins/sources/` path, and the standard
`<source-file>` + `<podspec>` entries are enough.

When you do ship it, two Capacitor-imposed rules make it resolve when a Capacitor
app (or ODC) consumes the plugin — both verified by the Phase 6 build:

- **Name everything after the Cordova plugin id.** `Package(name:)`, the library
  product, and the target must all be `com.outsystems.plugins.{plugin}` — not a
  friendly name. Capacitor references `.product(name: "{id}", package: "{id}")`,
  so any other name fails with `product '…' not found`.
- **Keep `https://github.com/apache/cordova-ios.git` as the first `apache` in the
  file.** `cap sync` rewrites it via
  `.replace('apache','ionic-team').replaceAll('cordova-ios','capacitor-swift-pm')`;
  an "apache"/"cordova-ios" substring in a comment above the dependency mangles
  the URL. See the iOS subsection in `build-verification.md` for the full
  rationale.

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "com.outsystems.plugins.{plugin}",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "com.outsystems.plugins.{plugin}",
                 targets: ["com.outsystems.plugins.{plugin}"])
    ],
    dependencies: [
        .package(url: "https://github.com/apache/cordova-ios.git", branch: "master"),
        // ... plugin SPM deps (e.g. firebase-ios-sdk) ...
    ],
    targets: [
        .target(
            name: "com.outsystems.plugins.{plugin}",
            dependencies: [
                .product(name: "Cordova", package: "cordova-ios"),
                // ... products from the SPM deps above ...
            ],
            path: "src/ios")
    ]
)
```

---

## `package.json`

```json
{
  "name": "com.outsystems.plugins.{plugin}",
  "version": "0.0.1",
  "description": "OutSystems Cordova plugin for {Plugin}",
  "keywords": ["cordova", "outsystems", "{plugin}"],
  "license": "MIT",
  "cordova": {
    "id": "com.outsystems.plugins.{plugin}",
    "platforms": ["android", "ios"]
  }
}
```

---

## `README.md`

Sections:
1. Brief description (one sentence).
2. Install: `cordova plugin add https://github.com/OutSystems/cordova-outsystems-{plugin}`
3. API — table of methods with parameters and return types. Must match the
   Capacitor plugin API exactly.
