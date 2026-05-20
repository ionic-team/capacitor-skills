# Cordova to Capacitor API Mappings

This reference provides detailed code mappings showing how Cordova patterns translate to Capacitor equivalents.

## Contents

- [JavaScript Bridge Pattern](#javascript-bridge-pattern)
- [iOS Native Pattern](#ios-native-pattern)
- [Android Native Pattern](#android-native-pattern)
- [Plugin Configuration](#plugin-configuration)
- [Key Differences Summary](#key-differences-summary)

---

## JavaScript Bridge Pattern

### Cordova

```javascript
// www/MyPlugin.js
var exec = require('cordova/exec');

exports.doSomething = function(arg, success, error) {
    exec(success, error, 'MyPlugin', 'doSomething', [arg]);
};
```

**Pattern:**
- Uses `cordova.exec()` function
- Callback-based (success/error functions)
- Positional array-based arguments
- String-based action routing

### Capacitor

```typescript
// src/definitions.ts
export interface MyPluginPlugin {
  doSomething(options: { arg: string }): Promise<{ result: string }>;
}

// src/web.ts
import { WebPlugin } from '@capacitor/core';
import type { MyPluginPlugin } from './definitions';

export class MyPluginWeb extends WebPlugin implements MyPluginPlugin {
  async doSomething(options: { arg: string }): Promise<{ result: string }> {
    // Web implementation
    return { result: 'success' };
  }
}
```

**Pattern:**
- TypeScript interfaces for type safety
- Promise-based (no callbacks)
- Named object parameters
- No explicit `exec()` call (handled by `@capacitor/core`)

### Key Differences

| Aspect | Cordova | Capacitor |
|--------|---------|-----------|
| Language | JavaScript | TypeScript |
| Async Pattern | Callbacks | Promises |
| Arguments | Positional array `[arg1, arg2]` | Named object `{ arg1, arg2 }` |
| Bridge | Explicit `exec()` call | Automatic via `registerPlugin()` |
| Web Support | Optional | Built-in with `WebPlugin` |

### Stringified JSON Blob Arguments

A common Cordova anti-pattern: the JavaScript layer passes a pre-serialized
JSON string and the native handler parses it.

**Cordova:**
```javascript
exports.submitOrder = function(orderDetails, accessToken, success, error) {
    exec(success, error, 'MyPlugin', 'submitOrder',
         [JSON.stringify(orderDetails), accessToken]);
};
```

**Native handler (Android Kotlin):**
```kotlin
private fun submitOrder(args: JSONArray) {
    val details = gson.fromJson(args.getString(0), OrderDetails::class.java)
    // ...
}
```

**Native handler (iOS Swift):**
```swift
guard let json = command.argument(at: 0) as? String,
      let data = json.data(using: .utf8),
      let details = try? JSONDecoder().decode(OrderDetails.self, from: data) else { return }
```

**Capacitor migration:** Replace the stringified blob with a strongly-typed
TypeScript interface. Read the native parsing site to capture the schema.

```typescript
// src/definitions.ts
export interface OrderDetails {
  amount: number;
  currency: string;
  // ... whatever fields the native data class actually decodes
}

export interface MyPlugin {
  submitOrder(options: {
    orderDetails: OrderDetails;
    accessToken?: string;
  }): Promise<OrderResult>;
}
```

```kotlin
// Android. Capacitor receives the typed object directly.
@PluginMethod
fun submitOrder(call: PluginCall) {
    val details = call.getObject("orderDetails")
    // map JSObject -> OrderDetails data class
}
```

**Migration YAML hint:**

```yaml
migration:
  cordova_to_capacitor_map:
    - cordova: "MyPlugin.submitOrder(JSON.stringify(details), token, ok, err)"
      capacitor: "MyPlugin.submitOrder({ orderDetails, accessToken })"
api:
  types:
    - name: OrderDetails
      kind: interface
      fields: [...]                # exact shape from the native parsing site
```

---

## iOS Native Pattern

### Cordova (Objective-C)

```objc
// CDVPlugin subclass
#import <Cordova/CDVPlugin.h>

@interface MyPlugin : CDVPlugin
- (void)doSomething:(CDVInvokedUrlCommand*)command;
@end

@implementation MyPlugin

- (void)doSomething:(CDVInvokedUrlCommand*)command {
    NSString* arg = [command.arguments objectAtIndex:0];

    // Implementation

    CDVPluginResult* result = [CDVPluginResult
        resultWithStatus:CDVCommandStatus_OK
        messageAsString:@"Success"];
    [self.commandDelegate sendPluginResult:result
        callbackId:command.callbackId];
}

@end
```

**Pattern:**
- Extends `CDVPlugin`
- Uses `CDVInvokedUrlCommand` parameter
- Extracts arguments by index from array
- Creates `CDVPluginResult` for response
- Sends result via `commandDelegate`

### Capacitor (Swift)

```swift
// CAPPlugin subclass
import Capacitor

@objc(MyPlugin)
public class MyPlugin: CAPPlugin {
    @objc func doSomething(_ call: CAPPluginCall) {
        guard let arg = call.getString("arg") else {
            call.reject("Missing arg parameter")
            return
        }

        // Implementation

        call.resolve(["result": "Success"])
    }
}
```

**Pattern:**
- Extends `CAPPlugin` (not `CDVPlugin`)
- Uses `CAPPluginCall` parameter (not `CDVInvokedUrlCommand`)
- Extracts arguments by name (not index)
- Direct `call.resolve()` / `call.reject()` (no `CDVPluginResult`)
- Requires `@objc` decorator for methods
- Requires `@objc(PluginName)` on class

### Key Differences

| Aspect | Cordova | Capacitor |
|--------|---------|-----------|
| Language | Objective-C (common) | Swift (preferred) |
| Base Class | `CDVPlugin` | `CAPPlugin` |
| Method Parameter | `CDVInvokedUrlCommand*` | `CAPPluginCall` |
| Argument Access | Index-based `objectAtIndex:0` | Named `getString("arg")` |
| Response | `CDVPluginResult` + delegate | `call.resolve()` / `call.reject()` |
| Method Decorator | Not required | `@objc` required |
| Class Decorator | Not required | `@objc(PluginName)` required |

---

## Android Native Pattern

### Cordova (Java)

```java
import org.apache.cordova.*;

public class MyPlugin extends CordovaPlugin {
    @Override
    public boolean execute(String action, JSONArray args,
                          CallbackContext callbackContext) {
        if (action.equals("doSomething")) {
            String arg = args.getString(0);

            // Implementation

            callbackContext.success("Success");
            return true;
        }
        return false;
    }
}
```

**Pattern:**
- Extends `CordovaPlugin`
- Single `execute()` method routes all actions
- Action matching via string comparison
- Extracts arguments by index from `JSONArray`
- Uses `CallbackContext` for responses
- Returns boolean indicating if action was handled

### Capacitor (Java)

```java
import com.getcapacitor.*;
import com.getcapacitor.annotation.CapacitorPlugin;

@CapacitorPlugin(name = "MyPlugin")
public class MyPlugin extends Plugin {
    @PluginMethod
    public void doSomething(PluginCall call) {
        String arg = call.getString("arg");
        if (arg == null) {
            call.reject("Missing arg parameter");
            return;
        }

        // Implementation

        JSObject ret = new JSObject();
        ret.put("result", "Success");
        call.resolve(ret);
    }
}
```

**Pattern:**
- Extends `Plugin` (not `CordovaPlugin`)
- Requires `@CapacitorPlugin` annotation on class
- Individual methods with `@PluginMethod` (no action router)
- Extracts arguments by name from `PluginCall`
- Direct `call.resolve()` / `call.reject()` (no `CallbackContext`)
- No boolean return value needed

### Capacitor (Kotlin - Preferred)

```kotlin
import com.getcapacitor.*
import com.getcapacitor.annotation.CapacitorPlugin

@CapacitorPlugin(name = "MyPlugin")
class MyPlugin : Plugin() {
    @PluginMethod
    fun doSomething(call: PluginCall) {
        val arg = call.getString("arg") ?: run {
            call.reject("Missing arg parameter")
            return
        }

        // Implementation

        call.resolve(JSObject().apply {
            put("result", "Success")
        })
    }
}
```

**Pattern:**
- Kotlin syntax with null-safety
- Same decorators as Java version
- Cleaner syntax with `?: run` for null handling
- Idiomatic Kotlin patterns

### Key Differences

| Aspect | Cordova | Capacitor |
|--------|---------|-----------|
| Language | Java (common) | Kotlin (preferred) |
| Base Class | `CordovaPlugin` | `Plugin` |
| Class Annotation | Not required | `@CapacitorPlugin(name = "...")` required |
| Routing | Single `execute()` with action string | Individual `@PluginMethod` functions |
| Arguments | Index-based `args.getString(0)` | Named `call.getString("arg")` |
| Response | `callbackContext.success/error()` | `call.resolve()` / `call.reject()` |
| Return Type | `boolean` (handled action?) | `void` |

---

## Plugin Configuration

### Cordova (plugin.xml)

```xml
<plugin id="com.example.myplugin" version="1.0.0">
    <name>MyPlugin</name>
    <js-module src="www/MyPlugin.js" name="MyPlugin">
        <clobbers target="cordova.plugins.MyPlugin" />
    </js-module>

    <platform name="ios">
        <config-file target="config.xml" parent="/*">
            <feature name="MyPlugin">
                <param name="ios-package" value="MyPlugin" />
            </feature>
        </config-file>
        <source-file src="src/ios/MyPlugin.m" />
        <header-file src="src/ios/MyPlugin.h" />
    </platform>

    <platform name="android">
        <config-file target="config.xml" parent="/*">
            <feature name="MyPlugin">
                <param name="android-package" value="com.example.plugin.MyPlugin" />
            </feature>
        </config-file>
        <source-file src="src/android/MyPlugin.java"
            target-dir="src/com/example/plugin" />
    </platform>
</plugin>
```

**Pattern:**
- XML-based configuration
- Manual feature registration in config.xml
- Source file mappings defined
- Platform-specific configurations
- JavaScript module exposure via `clobbers` or `merges`

### Capacitor (package.json + native registration)

```json
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

**iOS Registration (Swift):**
```swift
// No config.xml, plugin auto-discovered via @objc(PluginName)
@objc(MyPlugin)
public class MyPlugin: CAPPlugin {
    // ...
}
```

**Android Registration (Java/Kotlin):**
```java
// Registered via @CapacitorPlugin annotation
@CapacitorPlugin(name = "MyPlugin")
public class MyPlugin extends Plugin {
    // ...
}
```

**Pattern:**
- JSON-based configuration in package.json
- No manual feature registration (auto-discovery)
- Native code uses decorators/annotations for registration
- No source file mappings needed
- JavaScript exposure via `registerPlugin()` in web layer

### Key Differences

| Aspect | Cordova | Capacitor |
|--------|---------|-----------|
| Config Format | XML (`plugin.xml`) | JSON (`package.json`) |
| Feature Registration | Manual in `config.xml` | Auto-discovery via annotations |
| Source Mapping | Explicit in `plugin.xml` | Standard directory structure |
| JS Exposure | `clobbers` / `merges` | `registerPlugin()` |
| Config File Mods | Supported via `<config-file>` | Not supported (manual) |

---

## Key Differences Summary

### Architecture Philosophy

**Cordova:**
- Build-time integration (platforms as build artifacts)
- Automatic native configuration via plugin.xml
- Callback-based asynchronous patterns
- Centralized action routing

**Capacitor:**
- Source-based integration (native projects as source code)
- Manual native configuration (documented in README)
- Promise-based asynchronous patterns
- Direct method invocation

### Migration Impact

| Change | Impact | Breaking Change? |
|--------|--------|------------------|
| Callbacks → Promises | API consumers must update | ✅ Yes |
| Positional → Named args | API structure changes | ✅ Yes |
| Objective-C → Swift | iOS implementation only | ❌ No (internal) |
| Java → Kotlin | Android implementation only | ❌ No (internal) |
| plugin.xml → package.json | Plugin structure only | ❌ No (internal) |
| Auto config → Manual | Setup process changes | ⚠️ Yes (setup) |

### What Users Must Change

When migrating from Cordova to Capacitor plugin:

**JavaScript/TypeScript:**
```javascript
// Before (Cordova)
cordova.plugins.MyPlugin.doSomething(
    "arg",
    function(result) { console.log(result); },
    function(error) { console.error(error); }
);

// After (Capacitor)
import { MyPlugin } from 'my-plugin';

try {
    const result = await MyPlugin.doSomething({ arg: "arg" });
    console.log(result);
} catch (error) {
    console.error(error);
}
```

**Native Configuration:**
```diff
# Before (Cordova)
cordova plugin add my-plugin
# Automatic native configuration

# After (Capacitor)
npm install my-plugin
+ # Manual steps required (documented in README):
+ # iOS: Add permissions to Info.plist
+ # Android: Add permissions to AndroidManifest.xml
+ # Run: npx cap sync
```
