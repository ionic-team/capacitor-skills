# Example Migration Analysis

This reference provides a complete example of a Cordova plugin migration analysis following the recommended format.

## User Request

> "Analyze this Cordova plugin for migrating to Capacitor"

## Response Template

```markdown
## Migration Overview

I've analyzed the plugin structure for Capacitor migration:

**Plugin Name:** Camera Plugin
**Plugin ID:** cordova-plugin-camera
**Purpose:** Provides access to device camera for taking photos and selecting images from gallery
**Platforms:** iOS, Android
**Migration Complexity:** Moderate
**Migration Feasibility:** Straightforward with documented config steps

---

## ⚠️ Migration Blockers & Unsupported Patterns

⚠️ **Warnings Found:**

1. **Permission declarations** (plugin.xml:67-72)
   - Modifies AndroidManifest.xml for CAMERA permission
   - Modifies Info.plist for NSCameraUsageDescription
   - ✅ Workaround: Document manual configuration in README

2. **Framework dependency** (plugin.xml:88)
   - Adds CoreLocation.framework on iOS
   - ✅ Workaround: Add to Podfile manually

✅ **Good News:**
- No installation hooks detected
- No complex config-file modifications
- Standard plugin architecture
- Well-defined API surface

---

## Cordova Plugin Architecture

**JavaScript API:**
- Methods: `getPicture(success, error, options)`, `cleanup(success, error)`
- Bridge: Uses `cordova.exec()` with callback functions
- Arguments: Options object passed as positional array parameter

**iOS Implementation:**
- Class: `CDVCamera` (Objective-C)
- Base: Extends `CDVPlugin`
- Key Methods: `takePicture:`, `cleanup:`
- Features: Uses UIImagePickerController, handles image compression
- Response: CDVPluginResult with image data or file URI

**Android Implementation:**
- Class: `CameraLauncher` (Java)
- Base: Extends `CordovaPlugin`
- Router: `execute()` routes actions "takePicture" and "cleanup"
- Features: Intent-based camera launch, permission handling
- Response: CallbackContext with image data or file URI

**plugin.xml Configuration:**
- Platform mappings for iOS and Android
- Permission declarations (requires workaround)
- Framework dependencies (requires workaround)

---

## Capacitor Plugin Architecture (Target)

**TypeScript API:**
- Interface: Typed method signatures in `definitions.ts`
- Methods: `getPhoto(options): Promise<Photo>`, `cleanup(): Promise<void>`
- Bridge: `registerPlugin()` with Promise-based returns
- Arguments: Strongly-typed options objects

**iOS Implementation:**
- Class: `CameraPlugin` (Swift preferred)
- Base: Extends `CAPPlugin`
- Methods: `@objc func getPhoto(_ call: CAPPluginCall)`, `@objc func cleanup(_ call: CAPPluginCall)`
- Features: Modern Swift patterns, async/await compatible
- Response: `call.resolve()` with JSObject

**Android Implementation:**
- Class: `CameraPlugin` (Kotlin preferred)
- Base: Extends `Plugin`
- Methods: `@PluginMethod fun getPhoto(call: PluginCall)`, `@PluginMethod fun cleanup(call: PluginCall)`
- Features: Kotlin coroutines, Activity Result API
- Response: `call.resolve()` with JSObject

**package.json Configuration:**
- NPM metadata and Capacitor plugin config
- Manual native configuration documented in README

---

## Architecture Transformation

\`\`\`
CORDOVA PLUGIN                         CAPACITOR PLUGIN
═══════════════                        ════════════════

JavaScript Layer:                      TypeScript Layer:
┌──────────────────────┐              ┌───────────────────────┐
│ www/Camera.js        │              │ src/definitions.ts    │
│                      │              │                       │
│ getPicture(          │              │ interface Camera {    │
│   success,           │─────────────▶│   getPhoto(options):  │
│   error,             │              │     Promise<Photo>    │
│   options)           │              │ }                     │
│                      │              │                       │
│ exec(success, error, │              │ src/web.ts            │
│   'Camera',          │              │ (web fallback impl)   │
│   'takePicture',     │              │                       │
│   [options])         │              │                       │
└──────────────────────┘              └───────────────────────┘
         │                                      │
         │ Cordova Bridge                       │ Capacitor Bridge
         │ (callbacks)                          │ (Promises)
         ▼                                      ▼

iOS Layer:                             iOS Layer:
┌──────────────────────┐              ┌───────────────────────┐
│ CDVCamera.m          │              │ CameraPlugin.swift    │
│ (Objective-C)        │─────────────▶│ (Swift)               │
│                      │              │                       │
│ @interface CDVCamera │              │ @objc(CameraPlugin)   │
│   : CDVPlugin        │              │ class CameraPlugin:   │
│                      │              │   CAPPlugin           │
│ - takePicture:       │              │                       │
│   (CDVInvokedUrlCmd) │              │ @objc func getPhoto(  │
│                      │              │   _ call:             │
│ CDVPluginResult      │              │   CAPPluginCall)      │
│   sendResult:        │              │                       │
└──────────────────────┘              │ call.resolve([...])   │
                                      └───────────────────────┘

Android Layer:                         Android Layer:
┌──────────────────────┐              ┌───────────────────────┐
│ CameraLauncher.java  │              │ CameraPlugin.kt       │
│ (Java)               │─────────────▶│ (Kotlin)              │
│                      │              │                       │
│ public class         │              │ @CapacitorPlugin(     │
│   CameraLauncher:    │              │   name = "Camera")    │
│   CordovaPlugin      │              │ class CameraPlugin :  │
│                      │              │   Plugin()            │
│ execute(action,      │              │                       │
│   args, callback) {  │              │ @PluginMethod         │
│   if ("takePicture") │              │ fun getPhoto(         │
│ }                    │              │   call: PluginCall)   │
│                      │              │                       │
│ callbackContext      │              │ call.resolve(         │
│   .success(...)      │              │   JSObject(...))      │
└──────────────────────┘              └───────────────────────┘

Configuration:                         Configuration:
┌──────────────────────┐              ┌───────────────────────┐
│ plugin.xml           │              │ package.json          │
│                      │─────────────▶│ + Manual native setup │
│ <platform="ios">     │              │                       │
│ <platform="android"> │              │ capacitor: {          │
│ <config-file>        │              │   ios: { src: "ios" } │
│ <framework>          │              │   android: {...}      │
│ <source-file>        │              │ }                     │
└──────────────────────┘              │                       │
                                      │ README.md:            │
                                      │ - iOS permissions     │
                                      │ - Android permissions │
                                      └───────────────────────┘

Key Transformations:
  • Callbacks → Promises (breaking change for consumers)
  • Positional args → Named object parameters
  • Single execute() router → Individual @PluginMethod functions
  • XML config → JSON config + documented manual steps
  • Objective-C → Swift (recommended)
  • Java → Kotlin (recommended)
\`\`\`

---

## Migration Roadmap

### Phase 1: TypeScript API Layer
- [ ] Create `src/definitions.ts` with TypeScript interfaces
- [ ] Define `CameraPlugin` interface with typed methods
- [ ] Create `src/web.ts` with web fallback implementation
- [ ] Convert callback-based API to Promise-based
- [ ] Map all options to strongly-typed interfaces

### Phase 2: iOS Native Layer
- [ ] Create `ios/Plugin/CameraPlugin.swift`
- [ ] Convert from CDVPlugin to CAPPlugin
- [ ] Modernize Objective-C code to Swift
- [ ] Update UIImagePickerController usage for modern iOS
- [ ] Replace CDVPluginResult with `call.resolve()`
- [ ] Add `@objc` decorators to methods

### Phase 3: Android Native Layer
- [ ] Create `android/src/main/java/.../CameraPlugin.kt`
- [ ] Convert from CordovaPlugin to Plugin
- [ ] Modernize Java code to Kotlin
- [ ] Replace Intent pattern with Activity Result API
- [ ] Add `@CapacitorPlugin` and `@PluginMethod` annotations
- [ ] Update permission handling to Capacitor pattern

### Phase 4: Configuration & Documentation
- [ ] Document required iOS permissions in README
- [ ] Document required Android permissions in README
- [ ] Create package.json with Capacitor metadata
- [ ] Remove plugin.xml
- [ ] Add TypeScript type definitions export
- [ ] Create migration guide for existing Cordova users

### Phase 5: Migration Completion & Cleanup
- [ ] Consolidate all migration documentation into single MIGRATION.md
- [ ] Remove intermediate .md files (status, TODO, implementation notes)
- [ ] Archive Cordova source files if needed
- [ ] Final testing and validation
- [ ] Update plugin README with migration summary

---

## Next Steps

This analysis is ready to feed into the **capacitor-plugin-dev** skill for implementation.

**Recommended Workflow:**

**For Simple/Moderate Plugins:**
1. Review migration blockers and plan workarounds
2. Use `capacitor-plugin-dev` skill to scaffold the Capacitor plugin
3. Implement TypeScript API based on the mapping above
4. Implement native iOS/Android code following the architecture transformation
5. Document manual configuration steps for users

**For Complex Plugins (THIS PLUGIN - RECOMMENDED):**
1. Review migration blockers and plan workarounds
2. Use `capacitor-plugin-dev` skill to assess complexity (Step 5)
3. Follow **incremental platform migration approach**:
   - Phase 1: TypeScript API layer → User checkpoint
   - Phase 2: iOS implementation → User inspection and approval
   - Phase 3: Android implementation → User inspection and approval
   - Phase 4: Web implementation → Final review
   - Phase 5: Consolidate documentation and cleanup intermediate files
4. Document manual configuration steps for users

**⚠️ This Plugin is Complex Because:**
- Moderate lines of code (~800 LOC)
- Multiple platform implementations (iOS, Android)
- Permission handling requirements
- Framework dependencies

**Why Incremental Migration is Recommended:**
For this camera plugin, migrating one platform at a time allows:
- ✅ Validate iOS camera implementation works before Android
- ✅ Test permission handling on iOS first
- ✅ Get user feedback on image handling approach
- ✅ Adjust compression/quality settings per platform
- ✅ Isolate platform-specific camera API issues

**For more details, you can request:**
- "Show me code examples for the getPhoto method"
- "Explain the iOS migration in detail"
- "What does the Android implementation look like?"
- "Walk through the permission handling conversion"
```

---

## Analysis with Hooks Example

For a plugin with hooks, the analysis would also include:

```markdown
## 🔧 Cordova Hooks Migration Analysis

**Hooks Detected:** 2 hook(s) found in plugin.xml

### Hook 1: Resource Copier (after_prepare)
**Location:** plugin.xml:42
**Script:** scripts/copyResources.js
**Purpose:** Copies custom fonts and assets to native projects

**Migration Strategy:** ✅ **Tier 1 - Capacitor Hook**

**Recommended Approach:**
\`\`\`json
// Document in README: Users should add to capacitor.config.json
{
  "hooks": {
    "capacitor:sync:end": "node node_modules/@company/plugin/scripts/copyResources.js"
  }
}
\`\`\`

**Implementation Notes:**
- Script needs minor modifications to support Capacitor project structure
- Change paths from `platforms/ios` to `ios/App`
- Change paths from `platforms/android` to `android/app`

---

### Hook 2: Dependency Installer (after_plugin_install)
**Location:** plugin.xml:45
**Script:** scripts/installNativeDeps.js
**Purpose:** Installs CocoaPods dependencies for iOS

**Migration Strategy:** ⚠️ **Tier 2 - Custom Script**

**Recommended Approach:**
\`\`\`json
// Add to plugin's package.json
{
  "scripts": {
    "postinstall": "node scripts/installNativeDeps.js && npx cap sync ios"
  }
}
\`\`\`

**Implementation Notes:**
- Script runs automatically after `npm install`
- Users may need to run `pod install` manually if postinstall fails
- Document manual steps in README as fallback

---

## 📋 Hooks Migration Summary

**Total Hooks:** 2
- ✅ **Tier 1 (Capacitor Hooks):** 1 - Can be converted directly
- ⚠️ **Tier 2 (Custom Scripts):** 1 - Requires npm scripts
- ❌ **Tier 3 (Blockers):** 0 - No migration blockers

**Overall Assessment:**
Hooks are not a significant concern for migration. Both hooks have clear conversion paths.

**Recommended Next Steps:**
1. Modify `copyResources.js` for Capacitor project structure
2. Add `postinstall` script to package.json
3. Document both hooks in plugin README
```

---

## Key Takeaways

**A complete migration analysis should include:**

1. ✅ **Migration Overview** - High-level assessment
2. ✅ **Unsupported Patterns** - Blockers and warnings upfront
3. ✅ **Hooks Analysis** - If hooks are present (detailed three-tier breakdown)
4. ✅ **Architecture Summary** - Current Cordova structure
5. ✅ **Architecture Mapping** - Target Capacitor structure
6. ✅ **ASCII Visualization** - Before/after transformation diagram
7. ✅ **Migration Roadmap** - Phased implementation checklist
8. ✅ **Next Steps** - Workflow recommendations

**When to recommend incremental migration:**
- Plugin has >800 LOC
- Multiple platforms with different implementations
- Complex native dependencies
- Permission handling
- Multiple public API methods (>5)
