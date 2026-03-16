---
name: capacitor-plugin-skill
description: Use this skill when the user asks to "create a Capacitor plugin", "build a native plugin", "develop Capacitor plugin", "scaffold plugin", "gather plugin requirements", or mentions working with Capacitor native bridges, iOS plugins, Android plugins, @capacitor/core, or plugin development. Guides comprehensive Capacitor plugin development including requirements gathering, architecture design, TypeScript API creation, native iOS/Android implementations, build configuration, and testing strategies.
version: 1.0.0
---

# Capacitor Plugin Development

This skill guides the complete lifecycle of Capacitor plugin development, from gathering requirements through implementation and testing. Use this when building custom native functionality that needs to be exposed to web applications through Capacitor.

## When to Use This Skill

✅ **Use this skill when:**
- Creating a new Capacitor plugin from scratch
- Adding native functionality (camera, sensors, storage, etc.) to a Capacitor app
- Designing plugin architecture and API contracts
- Implementing native code for iOS (Swift) or Android (Kotlin/Java)
- Bridging native APIs to JavaScript/TypeScript
- Setting up plugin configuration and build systems
- Writing tests for Capacitor plugins

❌ **Do NOT use this skill for:**
- Building standard Capacitor apps (use Capacitor documentation instead)
- Web-only features that don't require native bridges
- Modifying existing Capacitor core plugins
- General iOS or Android app development without Capacitor context

---

## Overview

Capacitor plugins bridge native platform capabilities to web applications. A well-designed plugin:
- Provides a clean, typed TypeScript API
- Handles platform differences gracefully
- Includes web implementations for testing
- Follows Capacitor conventions and best practices
- Is testable and maintainable

---

## Development Workflow

### Phase 0: Plugin Scaffolding (Optional)

If starting a new plugin from scratch, **gather all required information first**, then use the Capacitor plugin generator with all options provided via command-line flags (required for non-interactive environments).

#### Step 1: Gather Plugin Information

Ask the user for these details (or suggest based on context):

**1. Directory/Folder Name**
- Where should the plugin be created?
- Suggest: `capacitor-{feature}` or `capacitor-{company}-{feature}`
- Examples: `capacitor-battery`, `capacitor-device-info`, `capacitor-acme-scanner`

**2. Plugin Purpose**
- What does this plugin do? (brief description)
- Example: "Access device battery status"

**3. Organization/Company Name**
- Is this for a company/organization?
- Used for npm scope: `@company/plugin-name`
- If personal: use username or leave unscoped
- Examples: `@acme`, `@mycompany`, `@johndoe`

**4. Plugin Name (Base Name)**
- What should the plugin be called?
- Extract from purpose (e.g., "battery" from "battery status")
- **Avoid redundancy**: Use short, clear names
- Examples: `battery`, `device-info`, `scanner` (NOT `battery-plugin`, `device-info-plugin`)

**5. Class Name**
- Derive from plugin name
- **Critical**: Avoid stuttering! Don't add "Plugin" if it's already implied
- Pattern: `{FeatureName}` (e.g., `Battery`, `DeviceInfo`, `Scanner`)
- The generator will use this as-is, so `Battery` becomes `BatteryPlugin.swift` automatically
- ❌ Bad: `BatteryPlugin` → creates `BatteryPluginPlugin.swift`
- ✅ Good: `Battery` → creates `BatteryPlugin.swift`

**6. Package ID (Reverse DNS)**
- Format: `com.{company}.{pluginname}`
- Use lowercase, no hyphens
- Examples: `com.acme.battery`, `com.mycompany.deviceinfo`

**7. Author Information**
- Name and email
- Example: `"John Doe <john@acme.com>"`

**8. Repository URL**
- Where will this be hosted?
- Example: `https://github.com/acme/capacitor-battery`

**9. License**
- Default: `MIT`
- Other options: `Apache-2.0`, `BSD-3-Clause`, `ISC`

#### Step 2: Build the Command

Once all information is gathered, construct the command:

```bash
cd {parent-directory}

npm init @capacitor/plugin {folder-name} -- \
  --name "{org}/{package-name}" \
  --package-id "{reverse-dns-id}" \
  --class-name "{ClassName}" \
  --description "{description}" \
  --author "{name} <{email}>" \
  --license "{license}" \
  --repo "{repo-url}"
```

#### Example: Battery Plugin

**Gathered Information:**
- Directory: `capacitor-battery`
- Purpose: "Access device battery level and charging status"
- Organization: `@acme`
- Base name: `battery`
- Class name: `Battery` (NOT `BatteryPlugin`)
- Package ID: `com.acme.battery`
- Author: `Jane Developer <jane@acme.com>`
- Repo: `https://github.com/acme/capacitor-battery`
- License: `MIT`

**Generated Command:**
```bash
npm init @capacitor/plugin capacitor-battery -- \
  --name "@acme/capacitor-battery" \
  --package-id "com.acme.battery" \
  --class-name "Battery" \
  --description "Access device battery level and charging status" \
  --author "Jane Developer <jane@acme.com>" \
  --license "MIT" \
  --repo "https://github.com/acme/capacitor-battery"
```

**Result:** Creates `capacitor-battery/` directory with:
- Package name: `@acme/capacitor-battery`
- iOS class: `BatteryPlugin.swift` (automatically adds "Plugin" suffix)
- Android class: `BatteryPlugin.kt`
- TypeScript: `Battery` exported from definitions
- ✅ No stuttering!

#### Naming Anti-Patterns to Avoid

| ❌ Bad | ✅ Good | Result |
|--------|---------|--------|
| `--class-name "BatteryPlugin"` | `--class-name "Battery"` | `BatteryPlugin.swift` |
| `--class-name "DeviceInfoPlugin"` | `--class-name "DeviceInfo"` | `DeviceInfoPlugin.swift` |
| `--class-name "QRScannerPlugin"` | `--class-name "QRScanner"` | `QRScannerPlugin.swift` |

**Key Rule**: The generator automatically appends "Plugin" to class names, so **never include "Plugin" in `--class-name`**.

#### Step 3: Run the Command

```bash
# Navigate to parent directory
cd /path/to/projects

# Run the generated command
npm init @capacitor/plugin capacitor-battery -- \
  --name "@acme/capacitor-battery" \
  --package-id "com.acme.battery" \
  --class-name "Battery" \
  --description "Access device battery level and charging status" \
  --author "Jane Developer <jane@acme.com>" \
  --license "MIT" \
  --repo "https://github.com/acme/capacitor-battery"

# The plugin is created in ./capacitor-battery/
cd capacitor-battery
```

#### What Gets Created

The generator creates a complete plugin structure in the specified directory:

```
capacitor-battery/
├── src/                           # TypeScript source
│   ├── definitions.ts             # Battery interface
│   ├── web.ts                     # BatteryWeb class
│   └── index.ts                   # Exports Battery plugin
├── ios/Sources/BatteryPlugin/     # iOS implementation
│   ├── Battery.swift              # Implementation class
│   └── BatteryPlugin.swift        # Plugin bridge (auto-named)
├── android/src/main/kotlin/       # Android implementation
│   ├── Battery.kt                 # Implementation class
│   └── BatteryPlugin.kt           # Plugin bridge (auto-named)
├── example-app/                   # Test application
├── Package.swift                  # Swift Package Manager
├── package.json                   # NPM configuration
└── README.md                      # Generated documentation
```

**Skip this phase if:**
- Working with an existing plugin
- Using a custom project structure
- Building a quick prototype without publishing

---

### Phase 1: Requirements Gathering

Before writing code, understand what the plugin needs to accomplish. Use these questions to guide discovery:

#### Functional Requirements
1. **What native capability does this plugin expose?**
   - Example: "Access device battery status", "Scan QR codes", "Encrypt local data"

2. **What platforms need to be supported?**
   - iOS only, Android only, or both?
   - Does it need a web implementation for testing?

3. **What data flows between native and web?**
   - Input parameters (types, validation requirements)
   - Return values (success data, error cases)
   - Events or callbacks needed?

4. **What permissions are required?**
   - iOS: Info.plist entries (camera, location, etc.)
   - Android: AndroidManifest.xml permissions

#### Technical Constraints
5. **Are there platform-specific limitations?**
   - iOS-only APIs (e.g., ARKit)
   - Android-only features (e.g., NFC)
   - Minimum OS versions required

6. **What error cases need handling?**
   - Permission denied
   - Feature unavailable on device
   - Network failures (if applicable)

7. **Is this plugin reusable or project-specific?**
   - Published to npm or internal use only?
   - Versioning and backward compatibility needs

#### Example: Battery Status Plugin

```typescript
// User request: "I need to check battery level and charging status"

// Gathered requirements:
// - Read battery percentage (0-100)
// - Check if device is charging (boolean)
// - Listen for battery changes (event)
// - Support iOS + Android
// - No special permissions needed
// - Graceful degradation on web (mock data)
```

### Phase 2: Design Plugin Architecture

Based on requirements, design the plugin structure. See **[reference/architecture-patterns.md](reference/architecture-patterns.md)** for detailed patterns.

#### Plugin Structure

```
my-capacitor-plugin/
├── package.json              # NPM package config
├── Package.swift             # Swift Package Manager config (iOS)
├── src/
│   ├── definitions.ts        # TypeScript API definitions
│   ├── web.ts                # Web implementation
│   └── index.ts              # Export plugin instance
├── ios/
│   ├── Sources/
│   │   └── MyPlugin/
│   │       ├── MyPlugin.swift        # Implementation class
│   │       └── MyPluginPlugin.swift  # Plugin bridge class
│   └── Tests/
│       └── MyPluginTests/            # Unit tests
├── android/
│   └── src/main/
│       ├── java/                     # Java implementation (alternative)
│       └── kotlin/                   # Kotlin implementation (recommended)
│           └── MyPlugin.kt           # Implementation class
│           └── MyPluginPlugin.kt     # Plugin bridge class
└── README.md                 # Plugin documentation
```

#### API Design Principles

1. **Use clear, semantic method names**
   ```typescript
   ✅ getBatteryStatus()
   ❌ checkBattery(), battery(), status()
   ```

2. **Return promises for async operations**
   ```typescript
   ✅ async getBatteryStatus(): Promise<BatteryInfo>
   ❌ getBatteryStatus(callback: Function)
   ```

3. **Use typed interfaces**
   ```typescript
   interface BatteryInfo {
     level: number;      // 0-100
     isCharging: boolean;
   }
   ```

4. **Handle errors consistently**
   ```typescript
   try {
     const status = await BatteryPlugin.getBatteryStatus();
   } catch (error) {
     // error.message = "Battery API not available"
   }
   ```

See **[reference/api-design.md](reference/api-design.md)** for comprehensive API design patterns.

### Phase 3: TypeScript API Implementation

Define the plugin's public API in `src/definitions.ts`. This is the contract between web and native code.

#### Example: Battery Plugin API

```typescript
// src/definitions.ts
export interface BatteryPluginPlugin {
  /**
   * Get current battery status
   * @returns Battery level (0-100) and charging state
   * @throws Error if battery API unavailable
   */
  getBatteryStatus(): Promise<BatteryInfo>;

  /**
   * Listen for battery changes
   * @param eventName - 'batteryChange'
   * @param listenerFunc - Callback with new battery info
   */
  addListener(
    eventName: 'batteryChange',
    listenerFunc: (info: BatteryInfo) => void,
  ): Promise<PluginListenerHandle> & PluginListenerHandle;
}

export interface BatteryInfo {
  level: number;      // Percentage: 0-100
  isCharging: boolean;
}
```

#### Web Implementation (for Testing)

```typescript
// src/web.ts
import { WebPlugin } from '@capacitor/core';
import type { BatteryPluginPlugin, BatteryInfo } from './definitions';

export class BatteryPluginWeb extends WebPlugin implements BatteryPluginPlugin {
  async getBatteryStatus(): Promise<BatteryInfo> {
    // Use Web Battery API if available, otherwise mock
    if ('getBattery' in navigator) {
      const battery = await (navigator as any).getBattery();
      return {
        level: Math.round(battery.level * 100),
        isCharging: battery.charging,
      };
    }

    // Mock data for testing
    return {
      level: 85,
      isCharging: false,
    };
  }
}
```

See **[reference/typescript-implementation.md](reference/typescript-implementation.md)** for complete TypeScript patterns.

### Phase 4: Native iOS Implementation

Implement the plugin in Swift using **Swift Package Manager**. See **[reference/ios-implementation.md](reference/ios-implementation.md)** for detailed patterns.

#### Key Concepts

1. **Two-file pattern**: Plugin bridge class + Implementation class
2. **Use CAPBridgedPlugin** protocol for modern plugins
3. **Swift Package Manager** for dependencies (not CocoaPods)
4. **Call `resolve()` or `reject()` on the call object**
5. **Separate business logic from bridge code**

#### Example: iOS Battery Plugin

```swift
// ios/Sources/BatteryPlugin/BatteryPluginPlugin.swift (Bridge class)
import Foundation
import Capacitor

@objc(BatteryPluginPlugin)
public class BatteryPluginPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "BatteryPluginPlugin"
    public let jsName = "BatteryPlugin"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "getBatteryStatus", returnType: CAPPluginReturnPromise)
    ]

    private let implementation = BatteryPlugin()

    @objc func getBatteryStatus(_ call: CAPPluginCall) {
        let result = implementation.getBatteryStatus()
        call.resolve(result)
    }
}

// ios/Sources/BatteryPlugin/BatteryPlugin.swift (Implementation class)
import Foundation
import UIKit

@objc public class BatteryPlugin: NSObject {
    @objc public func getBatteryStatus() -> [String: Any] {
        UIDevice.current.isBatteryMonitoringEnabled = true

        let level = UIDevice.current.batteryLevel
        let isCharging = UIDevice.current.batteryState == .charging ||
                        UIDevice.current.batteryState == .full

        return [
            "level": Int(level * 100),
            "isCharging": isCharging
        ]
    }
}
```

### Phase 5: Native Android Implementation

Implement in Kotlin (recommended) or Java using the **two-class pattern**. See **[reference/android-implementation.md](reference/android-implementation.md)** for detailed patterns.

#### Key Concepts

1. **Two-class pattern**: Plugin class + Implementation class
2. **Separate business logic** from Capacitor bridge code
3. **Use Kotlin** for modern, concise code

#### Example: Android Battery Plugin

```kotlin
// android/src/main/kotlin/BatteryPluginPlugin.kt (Plugin class)
package com.example.battery

import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.getcapacitor.JSObject

@CapacitorPlugin(name = "BatteryPlugin")
class BatteryPluginPlugin : Plugin() {
    private val implementation = BatteryPlugin()

    @PluginMethod
    fun getBatteryStatus(call: PluginCall) {
        val result = implementation.getBatteryStatus(context)
        call.resolve(result)
    }
}

// android/src/main/kotlin/BatteryPlugin.kt (Implementation class)
package com.example.battery

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import com.getcapacitor.JSObject

class BatteryPlugin {
    fun getBatteryStatus(context: Context): JSObject {
        val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val batteryStatus = context.registerReceiver(null, filter)

        val level = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val status = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1

        val batteryPct = if (scale > 0) (level / scale.toFloat() * 100).toInt() else 0
        val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                        status == BatteryManager.BATTERY_STATUS_FULL

        return JSObject().apply {
            put("level", batteryPct)
            put("isCharging", isCharging)
        }
    }
}
```

### Phase 6: Configuration & Build Setup

Configure the plugin for proper building and registration. See **[reference/configuration.md](reference/configuration.md)** for complete setup.

#### Key Files

1. **package.json** - Define capacitor metadata:
   ```json
   {
     "name": "@company/capacitor-battery",
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

2. **Package.swift** - Swift Package Manager configuration:
   ```swift
   // swift-tools-version: 5.9
   import PackageDescription

   let package = Package(
       name: "BatteryPlugin",
       platforms: [.iOS(.v15)],
       products: [
           .library(name: "BatteryPlugin", targets: ["BatteryPlugin"])
       ],
       dependencies: [
           .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "6.0.0")
       ],
       targets: [
           .target(
               name: "BatteryPlugin",
               dependencies: [
                   .product(name: "Capacitor", package: "capacitor-swift-pm"),
                   .product(name: "Cordova", package: "capacitor-swift-pm")
               ],
               path: "ios/Sources/BatteryPlugin"
           ),
           .testTarget(
               name: "BatteryPluginTests",
               dependencies: ["BatteryPlugin"],
               path: "ios/Tests/BatteryPluginTests"
           )
       ]
   )
   ```

3. **Android Configuration** - Update `build.gradle` if needed

### Phase 7: Testing

Write tests for TypeScript, iOS, and Android implementations. See **[reference/testing-strategies.md](reference/testing-strategies.md)** for comprehensive testing patterns.

#### Testing with the Example App

The `create-capacitor-plugin` template includes an **example-app** directory for testing your plugin with a real Capacitor application.

**Using the Example App:**

1. **Build your plugin:**
   ```bash
   npm run build
   ```

2. **Navigate to example app:**
   ```bash
   cd example-app
   npm install
   npx cap sync
   ```

3. **Implement example usage:**
   Edit `example-app/src/js/example.js` (or similar) to demonstrate your plugin:
   ```typescript
   import { MyPlugin } from '@company/capacitor-myplugin';

   // Example: Call your plugin method
   async function testPlugin() {
     try {
       const result = await MyPlugin.methodName({ param: 'value' });
       console.log('Plugin result:', result);
     } catch (error) {
       console.error('Plugin error:', error);
     }
   }

   testPlugin();
   ```

4. **Test on platforms:**
   ```bash
   # Test on iOS
   npx cap open ios
   # Run in Xcode, check console logs

   # Test on Android
   npx cap open android
   # Run in Android Studio, check Logcat
   ```

5. **Verify functionality:**
   - Check that methods are callable
   - Verify correct return values
   - Test error cases (missing parameters, permission denied)
   - Confirm events fire correctly
   - Test on real devices (not just simulators)

**Example App Best Practices:**
- ✅ Implement realistic usage examples
- ✅ Test all public methods
- ✅ Include error handling examples
- ✅ Document expected behavior
- ✅ Test on real devices for permissions/hardware
- ✅ Keep example-app updated as plugin evolves

#### Testing Checklist

- [ ] **Example app implementation** - Create working example in example-app
- [ ] **TypeScript unit tests** - Test web implementation and type definitions
- [ ] **iOS unit tests** - Test Swift logic in XCTest
- [ ] **Android unit tests** - Test Kotlin/Java logic in JUnit
- [ ] **Integration tests** - Test full web-to-native flow with example-app
- [ ] **Error handling** - Test permission denied, unavailable features
- [ ] **Platform differences** - Test iOS and Android separately
- [ ] **Real device testing** - Verify on physical devices

### Phase 8: Quality Checks

Run Capacitor's built-in quality commands to ensure code quality and build success. These commands are part of every plugin template.

#### Verify All Platforms Build

```bash
# Verify all platforms build successfully
npm run verify

# This runs:
# - verify:web (TypeScript compilation)
# - verify:ios (Swift build and tests)
# - verify:android (Gradle build and tests)
```

Run `verify` before:
- Committing code
- Creating a pull request
- Publishing to npm
- After adding new native code

#### Format Code

```bash
# Auto-format all code to Capacitor conventions
npm run fmt

# This formats:
# - TypeScript/JavaScript (ESLint + Prettier)
# - Swift (SwiftLint)
# - Java/Kotlin (Prettier)
```

Run `fmt` to:
- Fix formatting issues automatically
- Ensure consistent code style
- Before committing changes

#### Lint Code

```bash
# Check code style without modifying files
npm run lint

# This checks:
# - TypeScript/JavaScript (ESLint + Prettier)
# - Swift (SwiftLint)
# - Reports issues without fixing
```

Run `lint` to:
- Verify code follows conventions
- Check before committing
- Run in CI/CD pipelines

#### Example Workflow

```bash
# 1. Make changes to plugin code
# ...

# 2. Format code automatically
npm run fmt

# 3. Verify all platforms build
npm run verify

# 4. Lint to catch any remaining issues
npm run lint

# 5. Run your own tests
npm test

# 6. Commit if all checks pass
git add .
git commit -m "feat: add new feature"
```

---

## Common Patterns

### Pattern 1: Permission Handling

Many plugins require runtime permissions. Handle them consistently:

```typescript
// TypeScript API
async requestPermissions(): Promise<PermissionStatus>;
async checkPermissions(): Promise<PermissionStatus>;
```

See **[reference/permission-patterns.md](reference/permission-patterns.md)** for platform-specific implementations.

### Pattern 2: Event Listeners

For continuous data (GPS, sensors, battery):

```typescript
addListener(
  eventName: 'dataChange',
  listenerFunc: (data: DataType) => void,
): Promise<PluginListenerHandle>;

removeAllListeners(): Promise<void>;
```

### Pattern 3: Error Handling

Use consistent error messages across platforms:

```typescript
// TypeScript
throw new Error('FEATURE_UNAVAILABLE: Camera not available on device');

// iOS
call.reject("FEATURE_UNAVAILABLE", "Camera not available on device")

// Android
call.reject("FEATURE_UNAVAILABLE", "Camera not available on device")
```

---

## Best Practices

### DO:
- ✅ **Use command-line flags with `npm init @capacitor/plugin`** for non-interactive environments
- ✅ Gather complete requirements before coding
- ✅ Design TypeScript API first (contract-first approach)
- ✅ Use TypeScript for type safety
- ✅ Implement web version for testing without devices
- ✅ Handle errors gracefully on all platforms
- ✅ Document all public methods with JSDoc
- ✅ **Run `npm run fmt` before committing** to auto-format code
- ✅ **Run `npm run verify` before publishing** to ensure all platforms build
- ✅ **Run `npm run lint` in CI/CD** to enforce code quality
- ✅ Test on real devices, not just simulators
- ✅ Follow platform conventions (Swift for iOS, Kotlin for Android)
- ✅ Use two-class pattern (bridge + implementation) for better testing

### DON'T:
- ❌ Mix concerns (keep plugin focused on one feature)
- ❌ Skip error handling
- ❌ Use callbacks instead of promises
- ❌ Forget web implementation
- ❌ Ignore platform-specific best practices
- ❌ Hard-code values that should be configurable
- ❌ Neglect testing
- ❌ **Commit code without running `fmt` and `verify`**
- ❌ Push to production without passing `lint` checks

---

## Quick Reference

### Plugin Development Commands

```bash
# Create new plugin (provide ALL options for non-interactive environments)
npm init @capacitor/plugin {folder-name} -- \
  --name "@company/plugin-name" \
  --package-id "com.company.pluginname" \
  --class-name "PluginName" \
  --description "Plugin description" \
  --author "Your Name <email@company.com>" \
  --license "MIT" \
  --repo "https://github.com/company/plugin-name"

# Build plugin
npm run build

# Quality checks (run these frequently!)
npm run fmt        # Auto-format all code
npm run lint       # Check code style
npm run verify     # Build all platforms (web, iOS, Android)

# Development workflow
npm run build      # Compile TypeScript
npm test           # Run tests
npm run fmt        # Format code
npm run verify     # Verify builds

# Add plugin to app
npm install /path/to/plugin
npx cap sync

# Open in IDE
npx cap open ios
npx cap open android
```

### Plugin Registration

```typescript
// In your app (src/main.ts or similar)
import { BatteryPlugin } from '@company/capacitor-battery';
registerPlugin('BatteryPlugin', BatteryPlugin);
```

### Documentation Links

- [Capacitor Plugin Guide](https://capacitorjs.com/docs/plugins)
- [iOS Plugin Development](https://capacitorjs.com/docs/plugins/ios)
- [Android Plugin Development](https://capacitorjs.com/docs/plugins/android)
- [Plugin APIs Reference](https://capacitorjs.com/docs/core-apis)

---

## Example: Complete Plugin Flow

**User Request**: "I need to access the device's flashlight"

**1. Requirements**:
- Turn flashlight on/off
- Check if flashlight available
- iOS + Android support
- No permissions needed (uses camera LED)

**2. API Design**:
```typescript
interface FlashlightPlugin {
  isAvailable(): Promise<{ available: boolean }>;
  turnOn(): Promise<void>;
  turnOff(): Promise<void>;
}
```

**3. Implementation Order**:
1. Create TypeScript definitions (`src/definitions.ts`)
2. Implement web stub (`src/web.ts`)
3. Implement iOS (`ios/Plugin/Plugin.swift`)
4. Implement Android (`android/src/main/java/FlashlightPlugin.kt`)
5. Add tests
6. Build and test on real devices

**4. Testing**:
```typescript
// In app code
const flashlight = new FlashlightPlugin();

const { available } = await flashlight.isAvailable();
if (available) {
  await flashlight.turnOn();
  setTimeout(() => flashlight.turnOff(), 3000);
}
```

---

## Next Steps

After creating a plugin:

1. **Publish to npm** (if reusable)
   ```bash
   npm publish
   ```

2. **Document usage** in README.md
   - Installation instructions
   - API reference
   - Code examples
   - Platform-specific notes

3. **Versioning** - Follow semantic versioning
   - MAJOR: Breaking API changes
   - MINOR: New features, backward compatible
   - PATCH: Bug fixes

4. **Maintenance**
   - Update for new Capacitor versions
   - Handle OS updates (iOS, Android)
   - Monitor issue reports

---

## Troubleshooting

### Common Issues

| Problem | Solution |
|---------|----------|
| **"Refusing to prompt in non-TTY environment"** | Use `npm init @capacitor/plugin {folder-name} --` with all flags (see Phase 0) |
| Plugin not found | Run `npx cap sync` after installing |
| iOS build fails | Check Package.swift and CAPBridgedPlugin implementation |
| Android build fails | Verify `build.gradle` and package names |
| Method not available | Check plugin is registered in app |
| Web version not working | Ensure plugin is registered with `registerPlugin()` |

### Debugging Tips

1. **Non-interactive environment error**:
   If you see "Refusing to prompt in non-TTY environment", provide all options:
   ```bash
   # ❌ This will fail in Claude Code
   npm init @capacitor/plugin

   # ✅ This works - all options provided
   npm init @capacitor/plugin {folder-name} -- \
     --name "@company/plugin" \
     --package-id "com.company.plugin" \
     --class-name "MyPlugin" \
     --description "Description" \
     --author "Name <email>" \
     --license "MIT" \
     --repo "https://github.com/..."
   ```

2. **Enable debug logging**:
   ```typescript
   // iOS: Check Xcode console
   // Android: Check Logcat
   ```

3. **Test platforms independently**:
   ```bash
   npx cap run ios
   npx cap run android
   ```

4. **Check native logs**:
   - iOS: Xcode → Window → Devices and Simulators → View Device Logs
   - Android: Android Studio → Logcat

---

## Reference Files

This skill includes detailed reference files for specific topics:

- **[reference/architecture-patterns.md](reference/architecture-patterns.md)** - Plugin structure and organization patterns
- **[reference/api-design.md](reference/api-design.md)** - TypeScript API design best practices
- **[reference/typescript-implementation.md](reference/typescript-implementation.md)** - Complete TypeScript implementation guide
- **[reference/ios-implementation.md](reference/ios-implementation.md)** - iOS native implementation patterns (Swift/Objective-C)
- **[reference/android-implementation.md](reference/android-implementation.md)** - Android native implementation patterns (Kotlin/Java)
- **[reference/configuration.md](reference/configuration.md)** - Build configuration and project setup
- **[reference/permission-patterns.md](reference/permission-patterns.md)** - Platform-specific permission handling
- **[reference/testing-strategies.md](reference/testing-strategies.md)** - Testing approaches for all layers
