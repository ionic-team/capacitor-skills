# Common Migration Patterns

This reference provides common patterns encountered during Cordova to Capacitor plugin migration and how to handle them.

## Contents

- [Callback to Promise Conversion](#callback-to-promise-conversion)
- [Permission Handling Migration](#permission-handling-migration)
- [Multi-Platform Configuration](#multi-platform-configuration)
- [Error Handling Consistency](#error-handling-consistency)
- [Plugin Analysis Patterns](#plugin-analysis-patterns)

---

## Callback to Promise Conversion

### Cordova Pattern (Callbacks)

```javascript
exports.doSomething = function(arg, success, error) {
    exec(success, error, 'MyPlugin', 'doSomething', [arg]);
};

// Usage
myPlugin.doSomething('value',
    function(result) { console.log(result); },
    function(err) { console.error(err); }
);
```

### Capacitor Pattern (Promises)

```typescript
export interface MyPluginPlugin {
  doSomething(options: { arg: string }): Promise<{ result: string }>;
}

// Usage
try {
    const result = await MyPlugin.doSomething({ arg: 'value' });
    console.log(result);
} catch (err) {
    console.error(err);
}
```

### Key Changes

| Aspect | Cordova | Capacitor |
|--------|---------|-----------|
| **Async Pattern** | Callbacks (success/error functions) | Promises (async/await) |
| **Arguments** | Positional + callbacks `(arg, success, error)` | Named object `({ arg })` |
| **Success Handling** | Callback function parameter | `await` or `.then()` |
| **Error Handling** | Error callback function | `try/catch` or `.catch()` |
| **Type Safety** | None (plain JavaScript) | TypeScript interfaces |

### Migration Checklist

- [ ] Convert callback parameters to Promise return type
- [ ] Move positional arguments into options object
- [ ] Add TypeScript type definitions
- [ ] Update error handling to use Promises
- [ ] Document breaking changes for plugin consumers

---

## Permission Handling Migration

### Cordova Pattern (Android)

```java
// Request permission
if (!cordova.hasPermission(Manifest.permission.CAMERA)) {
    cordova.requestPermission(this, REQUEST_CODE, Manifest.permission.CAMERA);
}

// Handle result
@Override
public void onRequestPermissionResult(int requestCode, String[] permissions, int[] grantResults) {
    if (requestCode == REQUEST_CODE) {
        if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            // Permission granted
        } else {
            // Permission denied
        }
    }
}
```

### Capacitor Pattern (Android)

```kotlin
@CapacitorPlugin(
    name = "MyPlugin",
    permissions = [
        Permission(strings = [Manifest.permission.CAMERA], alias = "camera")
    ]
)
class MyPlugin : Plugin() {
    @PluginMethod
    fun takePicture(call: PluginCall) {
        if (getPermissionState("camera") != PermissionState.GRANTED) {
            requestPermissionForAlias("camera", call, "cameraPermissionsCallback")
            return
        }
        // Permission granted, proceed
    }

    @PermissionCallback
    private fun cameraPermissionsCallback(call: PluginCall) {
        if (getPermissionState("camera") == PermissionState.GRANTED) {
            // Permission granted, retry operation
            takePicture(call)
        } else {
            call.reject("Permission denied")
        }
    }
}
```

### Cordova Pattern (iOS)

```objc
// Check permission
AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];

if (status == AVAuthorizationStatusNotDetermined) {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (granted) {
            // Permission granted
        }
    }];
}
```

### Capacitor Pattern (iOS)

```swift
@objc(MyPlugin)
public class MyPlugin: CAPPlugin {
    @objc func takePicture(_ call: CAPPluginCall) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            // Permission granted
            performCapture(call)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.performCapture(call)
                } else {
                    call.reject("Permission denied")
                }
            }
        default:
            call.reject("Permission denied")
        }
    }
}
```

### Key Changes

**Android:**
- Declare permissions in `@CapacitorPlugin` annotation
- Use `getPermissionState()` instead of `hasPermission()`
- Use `requestPermissionForAlias()` instead of `requestPermission()`
- Use `@PermissionCallback` for permission results

**iOS:**
- No framework-level changes (same iOS APIs)
- Must document required Info.plist entries

**Documentation:**
- Must document manual AndroidManifest.xml additions
- Must document manual Info.plist additions

### Migration Checklist

- [ ] Declare permissions in plugin annotation (Android)
- [ ] Convert permission checks to Capacitor APIs (Android)
- [ ] Add permission callback methods (Android)
- [ ] Document required AndroidManifest.xml changes
- [ ] Document required Info.plist changes
- [ ] Test permission flow on both platforms

---

## Multi-Platform Configuration

### Cordova Approach (Centralized)

**Single file controls everything:**

```xml
<!-- plugin.xml -->
<plugin id="com.example.myplugin" version="1.0.0">
    <name>MyPlugin</name>

    <!-- JavaScript -->
    <js-module src="www/MyPlugin.js" name="MyPlugin">
        <clobbers target="cordova.plugins.MyPlugin" />
    </js-module>

    <!-- iOS -->
    <platform name="ios">
        <config-file target="config.xml" parent="/*">
            <feature name="MyPlugin">
                <param name="ios-package" value="MyPlugin" />
            </feature>
        </config-file>
        <source-file src="src/ios/MyPlugin.m" />
        <header-file src="src/ios/MyPlugin.h" />
        <framework src="CoreLocation.framework" />
        <config-file target="*-Info.plist" parent="NSLocationWhenInUseUsageDescription">
            <string>App needs location</string>
        </config-file>
    </platform>

    <!-- Android -->
    <platform name="android">
        <config-file target="config.xml" parent="/*">
            <feature name="MyPlugin">
                <param name="android-package" value="com.example.MyPlugin" />
            </feature>
        </config-file>
        <source-file src="src/android/MyPlugin.java"
            target-dir="src/com/example" />
        <framework src="com.google.android.gms:play-services-location:18.0.0" />
        <config-file target="AndroidManifest.xml" parent="/*">
            <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
        </config-file>
    </platform>
</plugin>
```

**Characteristics:**
- Central configuration file
- Automatic native project modification
- Hook-based customization
- Build-time integration

### Capacitor Approach (Distributed)

**Configuration spread across multiple files:**

```json
// package.json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "capacitor": {
    "ios": {
      "src": "ios"
    },
    "android": {
      "src": "android"
    }
  }
}
```

```json
// capacitor.config.json (app-level, user-managed)
{
  "plugins": {
    "MyPlugin": {
      "apiKey": "user-provided-value"
    }
  }
}
```

```markdown
<!-- README.md (plugin documentation) -->
## Installation

### iOS Setup

1. Add to `ios/App/App/Info.plist`:
   \`\`\`xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>App needs location</string>
   \`\`\`

2. Add to `ios/App/Podfile`:
   \`\`\`ruby
   pod 'GoogleMaps'
   \`\`\`

### Android Setup

1. Add to `android/app/src/main/AndroidManifest.xml`:
   \`\`\`xml
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   \`\`\`

2. Add to `android/app/build.gradle`:
   \`\`\`gradle
   dependencies {
       implementation 'com.google.android.gms:play-services-location:21.0.1'
   }
   \`\`\`
```

**Characteristics:**
- Distributed configuration
- Manual native project modification
- Documentation-driven setup
- Source-based integration

### Key Differences

| Aspect | Cordova | Capacitor |
|--------|---------|-----------|
| **Config File** | `plugin.xml` (centralized) | `package.json` + README (distributed) |
| **Native Mods** | Automatic | Manual (documented) |
| **Feature Registration** | Manual in config.xml | Auto-discovery via annotations |
| **Frameworks** | Auto-injected | Manual Podfile/gradle |
| **Permissions** | Auto-added | Manual manifest edits |
| **Setup Process** | `cordova plugin add` (one step) | `npm install` + manual steps |

### Migration Checklist

- [ ] Convert plugin.xml metadata to package.json
- [ ] Document all iOS configuration steps in README
- [ ] Document all Android configuration steps in README
- [ ] Remove automatic config-file modifications
- [ ] Test manual setup process end-to-end
- [ ] Create setup verification script (optional)

---

## Error Handling Consistency

### Cordova Error Handling (Inconsistent)

**JavaScript:**
```javascript
error("Error message");  // String-based error
```

**Android:**
```java
callbackContext.error("Error");  // String-based
callbackContext.error(404);      // Int-based
```

**iOS:**
```objc
CDVPluginResult* result = [CDVPluginResult
    resultWithStatus:CDVCommandStatus_ERROR
    messageAsString:@"Error"];
```

**Issues:**
- Different patterns per platform
- No structured error codes
- No consistent error format

### Capacitor Error Handling (Consistent)

**TypeScript:**
```typescript
throw new Error("Error message");
// Or for structured errors:
throw {
    code: "ERROR_CODE",
    message: "Error message",
    details: { /* ... */ }
};
```

**Android:**
```kotlin
call.reject("Error message")
call.reject("Error message", "ERROR_CODE")
call.reject("Error message", "ERROR_CODE", null, errorData)
```

**iOS:**
```swift
call.reject("Error message")
call.reject("Error message", "ERROR_CODE")
call.reject("Error message", "ERROR_CODE", nil, errorData)
```

**Benefits:**
- Same API across all platforms
- Structured error support
- Type-safe error codes
- Consistent error format

### Best Practices

**Use the generator's canonical 4-code taxonomy.** The
`capacitor-plugin-generator` skill enforces these four error codes; any
custom codes you propose in the YAML must subtype one of these:

| Code | Use for |
| --- | --- |
| `UNAVAILABLE` | Feature not supported on this platform / device / session. |
| `PERMISSION_DENIED` | Runtime permission denied (or permanently denied). |
| `INVALID_PARAMETER` | Argument missing, wrong type, or out of range. |
| `OPERATION_FAILED` | Native operation failed for any other reason. |

**Define error codes:**
```typescript
// src/definitions.ts
export enum MyPluginError {
  UNAVAILABLE       = "UNAVAILABLE",
  PERMISSION_DENIED = "PERMISSION_DENIED",
  INVALID_PARAMETER = "INVALID_PARAMETER",
  OPERATION_FAILED  = "OPERATION_FAILED",
}
```

**Use structured errors:**
```typescript
// TypeScript
if (!options.url) {
  throw {
    code: MyPluginError.INVALID_PARAMETER,
    message: "URL is required",
    details: { parameter: "url" }
  };
}
```

```kotlin
// Android
if (url.isNullOrEmpty()) {
    call.reject("URL is required", "INVALID_PARAMETER")
    return
}
```

```swift
// iOS
guard let url = call.getString("url") else {
    call.reject("URL is required", "INVALID_PARAMETER")
    return
}
```

**Mapping Cordova error strings.** Cordova plugins typically pass free-form
error strings to `callbackContext.error(...)`. When migrating:

1. Group the original error strings into the four canonical buckets.
2. If a single bucket is too coarse for callers (e.g., `OPERATION_FAILED`
   covers both "network timeout" and "card declined"), add a structured
   `details.cause` field, never invent a new top-level code.
3. Preserve the original Cordova error string under `details.cordovaMessage`
   for backwards-compatibility logs.

### Migration Checklist

- [ ] Define error code enums
- [ ] Standardize error messages across platforms
- [ ] Use structured error format
- [ ] Convert Cordova error patterns to Capacitor
- [ ] Document error codes in plugin README
- [ ] Test error handling on all platforms

---

## Plugin Analysis Patterns

When analyzing a Cordova plugin, identify these patterns:

### Pattern 1: JavaScript Bridge Analysis

**Look for:**
```javascript
// www/MyPlugin.js
var exec = require('cordova/exec');

exports.doSomething = function(arg, success, error) {
    exec(success, error, 'MyPlugin', 'doSomething', [arg]);
};
```

**Extract:**
- **Plugin name**: `'MyPlugin'`
- **Action name**: `'doSomething'`
- **Arguments**: `[arg]` (positional array)
- **Callback functions**: `success`, `error`

**Map to Capacitor:**
```typescript
interface MyPluginPlugin {
  doSomething(options: { arg: string }): Promise<Result>;
}
```

### Pattern 2: iOS Implementation Analysis

**Look for:**
```objc
// src/ios/MyPlugin.m
- (void)doSomething:(CDVInvokedUrlCommand*)command {
    NSString* arg = [command.arguments objectAtIndex:0];
    // ... implementation ...
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}
```

**Extract:**
- Method signature matches action name
- `CDVInvokedUrlCommand` parameter
- Argument extraction from `command.arguments`
- `CDVPluginResult` creation and sending

**Map to Capacitor:**
```swift
@objc func doSomething(_ call: CAPPluginCall) {
    guard let arg = call.getString("arg") else {
        call.reject("Missing arg")
        return
    }
    // ... implementation ...
    call.resolve(["result": value])
}
```

### Pattern 3: Android Implementation Analysis

**Look for:**
```java
// src/android/MyPlugin.java
public boolean execute(String action, JSONArray args, CallbackContext callback) {
    if (action.equals("doSomething")) {
        String arg = args.getString(0);
        // ... implementation ...
        callback.success("Success");
        return true;
    }
    return false;
}
```

**Extract:**
- Extends `CordovaPlugin`
- `execute()` method routes actions
- Action string matching
- `JSONArray` argument extraction
- `CallbackContext` responses

**Map to Capacitor:**
```kotlin
@PluginMethod
fun doSomething(call: PluginCall) {
    val arg = call.getString("arg") ?: run {
        call.reject("Missing arg")
        return
    }
    // ... implementation ...
    call.resolve(JSObject().apply { put("result", value) })
}
```

### Pattern 4: plugin.xml Analysis

**Look for:**
```xml
<plugin id="com.example.myplugin">
    <js-module src="www/MyPlugin.js">
        <clobbers target="cordova.plugins.MyPlugin" />
    </js-module>
    <platform name="ios">
        <source-file src="src/ios/MyPlugin.m" />
        <framework src="CoreLocation.framework" />
        <config-file target="*-Info.plist">...</config-file>
    </platform>
    <platform name="android">
        <source-file src="src/android/MyPlugin.java" />
        <framework src="..." />
        <config-file target="AndroidManifest.xml">...</config-file>
    </platform>
</plugin>
```

**Extract:**
- Plugin ID and namespace
- JavaScript module exposure target
- iOS class name
- Android fully-qualified class name
- Framework dependencies
- Config file modifications (flag as blockers!)

**Flag:**
- ❌ Any `<config-file>` modifications → Manual steps required
- ❌ Any `<hook>` tags → Analyze with three-tier approach
- ⚠️ Framework dependencies → Document manual installation

---

## Migration Complexity Factors

### Factors that Increase Complexity

- ❌ Extensive config-file modifications (>3 files)
- ❌ Installation hooks or custom build scripts
- ❌ Dependencies on other Cordova plugins
- ❌ Platform-specific hacks or workarounds
- ❌ Large number of public API methods (>10)
- ❌ Complex data structures in arguments
- ❌ Undocumented native code behavior

### Factors that Reduce Complexity

- ✅ Simple exec() patterns with basic arguments
- ✅ Standard iOS/Android APIs (no custom frameworks)
- ✅ Well-documented code with clear patterns
- ✅ Few public API methods (<5)
- ✅ No plugin.xml config modifications
- ✅ No external dependencies

### Complexity Assessment

Use these factors to classify plugin as:

| Complexity | Criteria |
|------------|----------|
| **Simple** | <5 methods, no config mods, no hooks, standard APIs |
| **Moderate** | 5-10 methods, some config mods, convertible hooks, few dependencies |
| **Complex** | >10 methods, extensive config mods, hooks with blockers, heavy dependencies |
