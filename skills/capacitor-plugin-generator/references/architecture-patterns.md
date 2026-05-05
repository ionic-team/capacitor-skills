# Plugin Architecture Patterns

This reference covers structural patterns and organization strategies for Capacitor plugins.

## Standard Plugin Structure

```
my-capacitor-plugin/
├── package.json              # NPM package configuration
├── tsconfig.json             # TypeScript compiler config
├── capacitor.config.json     # Plugin metadata
├── README.md                 # Usage documentation
├── src/
│   ├── definitions.ts        # TypeScript interface definitions
│   ├── web.ts                # Web platform implementation
│   └── index.ts              # Plugin export and registration
├── ios/
│   └── Plugin/
│       ├── Plugin.swift      # iOS native implementation
│       └── Plugin.m          # Objective-C bridge/registration
├── android/
│   └── src/main/java/com/company/plugin/
│       └── Plugin.kt         # Android native implementation
├── dist/                     # Built JavaScript (generated)
└── tests/
    ├── web.test.ts
    ├── ios/
    └── android/
```

---

## Architecture Layers

### Layer 1: TypeScript Definitions (`src/definitions.ts`)

**Purpose**: Define the contract between web and native code

```typescript
// Pure interface - no implementation
export interface MyPluginPlugin {
  /**
   * Method description
   * @param options - Input parameters
   * @returns Promise with result data
   */
  methodName(options: MethodOptions): Promise<MethodResult>;
}

// Define all data structures
export interface MethodOptions {
  param1: string;
  param2?: number;  // Optional parameters
}

export interface MethodResult {
  success: boolean;
  data: string;
}
```

**Key principles**:
- Only interfaces, no implementation
- Document all parameters with JSDoc
- Use semantic names
- Group related types together

### Layer 2: Web Implementation (`src/web.ts`)

**Purpose**: Provide browser-based implementation for testing and PWA support

```typescript
import { WebPlugin } from '@capacitor/core';
import type { MyPluginPlugin, MethodOptions, MethodResult } from './definitions';

export class MyPluginWeb extends WebPlugin implements MyPluginPlugin {
  async methodName(options: MethodOptions): Promise<MethodResult> {
    // Option 1: Use web APIs if available
    if ('relevantAPI' in window) {
      const result = await window.relevantAPI.call(options.param1);
      return { success: true, data: result };
    }

    // Option 2: Provide mock implementation
    console.warn('MyPlugin web implementation: returning mock data');
    return {
      success: true,
      data: `Mock result for ${options.param1}`,
    };

    // Option 3: Throw if not supported
    throw this.unavailable('This feature is not available on web');
  }
}
```

**Web implementation strategies**:

| Strategy | When to Use | Example |
|----------|-------------|---------|
| **Web API** | Browser API exists | Geolocation, Battery, Notifications |
| **Mock data** | For testing only | Device info, hardware features |
| **Throw error** | No web equivalent | NFC, Bluetooth, specific sensors |
| **Polyfill** | Can simulate behavior | Storage, HTTP requests |

### Layer 3: Native iOS Implementation (`ios/Plugin/Plugin.swift`)

**Purpose**: Access iOS platform APIs and bridge to JavaScript

```swift
import Foundation
import Capacitor

@objc(MyPlugin)
public class MyPlugin: CAPPlugin {

    // Called from JavaScript
    @objc func methodName(_ call: CAPPluginCall) {
        // 1. Extract parameters
        guard let param1 = call.getString("param1") else {
            call.reject("Missing param1")
            return
        }
        let param2 = call.getInt("param2") ?? 0

        // 2. Perform native work
        let result = performNativeWork(param1, param2)

        // 3. Return to JavaScript
        call.resolve([
            "success": true,
            "data": result
        ])
    }

    private func performNativeWork(_ p1: String, _ p2: Int) -> String {
        // iOS-specific implementation
        return "iOS result"
    }
}
```

**iOS bridging file** (`Plugin.m`):
```objc
#import <Capacitor/Capacitor.h>

CAP_PLUGIN(MyPlugin, "MyPlugin",
    CAP_PLUGIN_METHOD(methodName, CAPPluginReturnPromise);
)
```

### Layer 4: Native Android Implementation (`android/.../Plugin.kt`)

**Purpose**: Access Android platform APIs and bridge to JavaScript

```kotlin
package com.company.plugin

import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.getcapacitor.JSObject

@CapacitorPlugin(name = "MyPlugin")
class MyPlugin : Plugin() {

    @PluginMethod
    fun methodName(call: PluginCall) {
        // 1. Extract parameters
        val param1 = call.getString("param1")
        if (param1 == null) {
            call.reject("Missing param1")
            return
        }
        val param2 = call.getInt("param2", 0)

        // 2. Perform native work
        val result = performNativeWork(param1, param2)

        // 3. Return to JavaScript
        val ret = JSObject()
        ret.put("success", true)
        ret.put("data", result)
        call.resolve(ret)
    }

    private fun performNativeWork(p1: String, p2: Int): String {
        // Android-specific implementation
        return "Android result"
    }
}
```

### Layer 5: Plugin Registration (`src/index.ts`)

**Purpose**: Export plugin for consumption by Capacitor apps

```typescript
import { registerPlugin } from '@capacitor/core';
import type { MyPluginPlugin } from './definitions';

const MyPlugin = registerPlugin<MyPluginPlugin>('MyPlugin', {
  web: () => import('./web').then(m => new m.MyPluginWeb()),
});

export * from './definitions';
export { MyPlugin };
```

---

## Architectural Patterns

### Pattern 1: Simple Request-Response

**Use when**: Single method call returns data synchronously

```typescript
// TypeScript
interface DataPlugin {
  getData(options: { id: string }): Promise<{ value: string }>;
}

// iOS
@objc func getData(_ call: CAPPluginCall) {
    let id = call.getString("id")
    let value = fetchData(id)
    call.resolve(["value": value])
}

// Android
@PluginMethod
fun getData(call: PluginCall) {
    val id = call.getString("id")
    val value = fetchData(id)
    call.resolve(JSObject().put("value", value))
}
```

### Pattern 2: Event Streaming

**Use when**: Native code pushes data continuously (GPS, sensors)

```typescript
// TypeScript
interface SensorPlugin {
  startMonitoring(): Promise<void>;
  stopMonitoring(): Promise<void>;
  addListener(
    eventName: 'sensorData',
    listenerFunc: (data: SensorData) => void,
  ): Promise<PluginListenerHandle>;
}

// iOS
@objc func startMonitoring(_ call: CAPPluginCall) {
    startSensorUpdates { data in
        self.notifyListeners("sensorData", data: data)
    }
    call.resolve()
}

// Android
@PluginMethod
fun startMonitoring(call: PluginCall) {
    startSensorUpdates { data ->
        notifyListeners("sensorData", data)
    }
    call.resolve()
}
```

### Pattern 3: Permission-Gated Access

**Use when**: Feature requires runtime permissions

```typescript
// TypeScript
interface CameraPlugin {
  checkPermissions(): Promise<PermissionStatus>;
  requestPermissions(): Promise<PermissionStatus>;
  takePhoto(): Promise<Photo>;
}

// iOS
@objc func takePhoto(_ call: CAPPluginCall) {
    // Check permissions first
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    if status != .authorized {
        call.reject("PERMISSION_DENIED")
        return
    }
    // Proceed with photo capture
}
```

### Pattern 4: Background Task

**Use when**: Long-running operations (downloads, uploads)

```typescript
// TypeScript
interface DownloadPlugin {
  startDownload(options: { url: string }): Promise<{ taskId: string }>;
  cancelDownload(options: { taskId: string }): Promise<void>;
  addListener(
    eventName: 'downloadProgress',
    listenerFunc: (progress: { taskId: string; percent: number }) => void,
  ): Promise<PluginListenerHandle>;
}

// Native implementations manage background tasks
// and send progress updates via notifyListeners()
```

---

## Data Flow Patterns

### Synchronous Flow (Simple)

```
JavaScript Call
     ↓
Plugin Bridge
     ↓
Native Method
     ↓
Return Result
     ↓
Promise Resolves
```

### Asynchronous Flow (with Callbacks)

```
JavaScript Call
     ↓
Plugin Bridge
     ↓
Native Method (starts async work)
     ↓
Callback/Completion Handler
     ↓
notify Listeners() or resolve()
     ↓
JavaScript Receives Event/Result
```

### Bidirectional Flow (Events)

```
JavaScript addListener()
     ↓
Plugin Registers Listener
     ↓
Native Code Monitors
     ↓
Event Occurs
     ↓
notifyListeners()
     ↓
JavaScript Callback Fires
     ↓
(repeat until removeListener())
```

---

## Error Handling Architecture

### Error Propagation Strategy

```typescript
// TypeScript - Define error codes
export enum PluginErrorCode {
  UNAVAILABLE = 'UNAVAILABLE',
  PERMISSION_DENIED = 'PERMISSION_DENIED',
  INVALID_PARAMETER = 'INVALID_PARAMETER',
  OPERATION_FAILED = 'OPERATION_FAILED',
}

// Use consistent error format
try {
  await plugin.method();
} catch (error) {
  // error.code = 'PERMISSION_DENIED'
  // error.message = 'Camera permission not granted'
}
```

```swift
// iOS - Reject with consistent codes
call.reject("PERMISSION_DENIED", "Camera permission not granted")
```

```kotlin
// Android - Same error codes
call.reject("PERMISSION_DENIED", "Camera permission not granted")
```

### Error Hierarchy

```
Plugin Errors
├── UNAVAILABLE - Feature not supported on platform
├── PERMISSION_DENIED - User denied permission
├── INVALID_PARAMETER - Bad input from JavaScript
└── OPERATION_FAILED - Native operation failed
    ├── NETWORK_ERROR (subtype)
    ├── HARDWARE_ERROR (subtype)
    └── TIMEOUT (subtype)
```

---

## Plugin Size and Scope

### Single Responsibility Principle

✅ **Good - Focused plugins**:
- `@capacitor/camera` - Only camera/photo functionality
- `@capacitor/geolocation` - Only location services
- `@capacitor/filesystem` - Only file operations

❌ **Bad - Kitchen sink plugins**:
- `@company/utilities` - Camera, GPS, files, sensors, etc.

### When to Split a Plugin

Split when:
- Plugin has > 10 unrelated methods
- Different features need different permissions
- Features have different platform support (iOS-only vs Android-only)
- Versioning/releases would benefit from independence

### Plugin Composition

Instead of one large plugin, compose smaller ones:

```typescript
// Instead of DeviceUtilsPlugin with 20 methods
import { Camera } from '@capacitor/camera';
import { Geolocation } from '@capacitor/geolocation';
import { Filesystem } from '@capacitor/filesystem';

// Use specific plugins
const photo = await Camera.getPhoto();
const position = await Geolocation.getCurrentPosition();
await Filesystem.writeFile({ path: 'photo.jpg', data: photo.base64String });
```

---

## Performance Considerations

### Minimize Bridge Crossings

```typescript
// ❌ Bad - Multiple calls
for (let i = 0; i < 100; i++) {
  await plugin.processItem(i);  // 100 bridge calls
}

// ✅ Good - Batch processing
await plugin.processBatch([0, 1, 2, ..., 99]);  // 1 bridge call
```

### Handle Large Data Efficiently

```typescript
// ❌ Bad - Pass large data through bridge
await plugin.processImage({ data: base64EncodedMegabytes });

// ✅ Good - Use file paths
await plugin.processImage({ filePath: '/path/to/image.jpg' });
```

### Use Events for Streams

```typescript
// ❌ Bad - Polling
setInterval(async () => {
  const data = await plugin.getSensorData();
}, 100);

// ✅ Good - Event listener
plugin.addListener('sensorData', (data) => {
  // Receives data as it's available
});
```

---

## Testing Architecture

### Layer Testing Strategy

| Layer | Test Type | Tools | Coverage Target |
|-------|-----------|-------|-----------------|
| TypeScript API | Unit tests | Jest | 80%+ |
| Web implementation | Unit tests | Jest + JSDOM | 70%+ |
| iOS native | XCTest | Xcode | 60%+ |
| Android native | JUnit | Android Studio | 60%+ |
| Integration | E2E tests | Appium/Detox | Key flows |

### Testability Guidelines

1. **Inject dependencies** - Don't hard-code platform APIs
   ```swift
   // ✅ Good - testable
   class MyPlugin: CAPPlugin {
       var locationManager: LocationManagerProtocol
       init(locationManager: LocationManagerProtocol = CLLocationManager()) {
           self.locationManager = locationManager
       }
   }
   ```

2. **Separate business logic** - Keep plugin code thin
   ```typescript
   // ✅ Good
   class DataProcessor {
       static process(input: string): string { /* logic */ }
   }
   class MyPluginWeb extends WebPlugin {
       async method(options: Options): Promise<Result> {
           const result = DataProcessor.process(options.input);
           return { result };
       }
   }
   ```

---

## Versioning Strategy

### Semantic Versioning for Plugins

- **MAJOR** (1.0.0 → 2.0.0)
  - Breaking API changes
  - Removed methods
  - Changed method signatures
  - Minimum Capacitor version bump

- **MINOR** (1.0.0 → 1.1.0)
  - New methods added
  - New features (backward compatible)
  - Deprecations (with warnings)

- **PATCH** (1.0.0 → 1.0.1)
  - Bug fixes
  - Documentation updates
  - Internal refactoring

### Deprecation Pattern

```typescript
/**
 * @deprecated Use newMethod() instead. Will be removed in v3.0.0
 */
async oldMethod(): Promise<void> {
  console.warn('oldMethod is deprecated, use newMethod');
  return this.newMethod();
}

async newMethod(): Promise<void> {
  // New implementation
}
```

---

## Security Considerations

### Input Validation

```typescript
// TypeScript - Validate before passing to native
async method(options: { url: string }): Promise<void> {
  if (!options.url.startsWith('https://')) {
    throw new Error('HTTPS required');
  }
  // Pass to native
}
```

### Sensitive Data Handling

```swift
// iOS - Don't log sensitive data
@objc func authenticate(_ call: CAPPluginCall) {
    let password = call.getString("password")
    // ❌ print("Password: \(password)")  // Never log secrets
    // ✅ print("Authentication attempt")
}
```

### Permission Best Practices

- Request minimum permissions needed
- Request permissions just-in-time (not at app launch)
- Provide clear rationale in permission dialogs
- Handle denial gracefully

---

## Plugin Lifecycle

```
Development → Testing → Publishing → Maintenance
     ↓            ↓          ↓            ↓
  Design API   Unit tests  npm publish  Bug fixes
  Implement    E2E tests   Tag release  Updates
  Document     Device test Documentation  Versioning
```

### Maintenance Checklist

- [ ] Monitor for Capacitor updates
- [ ] Test on new iOS/Android versions
- [ ] Update dependencies regularly
- [ ] Respond to issues/PRs
- [ ] Deprecate old APIs gracefully
- [ ] Keep documentation current

---

## Summary

**Key Architectural Principles**:

1. **Separation of concerns** - Each layer has a clear responsibility
2. **Type safety** - Use TypeScript interfaces as contracts
3. **Consistency** - Same patterns across iOS and Android
4. **Testability** - Design for unit and integration testing
5. **Performance** - Minimize bridge crossings, batch operations
6. **Security** - Validate inputs, protect sensitive data
7. **Maintainability** - Keep plugins focused and well-documented

**Remember**: Good architecture makes plugins easy to test, maintain, and extend.
