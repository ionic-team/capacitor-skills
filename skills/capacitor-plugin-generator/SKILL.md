---
name: capacitor-plugin-dev
description: Use this skill when the user asks to "create a Capacitor plugin", "build a native plugin", "develop Capacitor plugin", "scaffold plugin", "gather plugin requirements", "convert Cordova plugin", "migrate Cordova plugin to Capacitor", "convert this Cordova plugin", "Cordova to Capacitor migration", or mentions working with Capacitor native bridges, iOS plugins, Android plugins, @capacitor/core, plugin development, or converting/migrating from Cordova. Guides comprehensive Capacitor plugin development including requirements gathering, architecture design, TypeScript API creation, native iOS/Android implementations, build configuration, testing strategies, and Cordova-to-Capacitor migrations.
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

## Special Case: Converting Cordova Plugins to Capacitor

When converting an existing Cordova plugin to Capacitor, follow this specialized workflow to maximize automation and minimize user questions.

**⚠️ CRITICAL FOR LARGE MIGRATIONS:**
For complex plugins (>2000 LOC, >15 methods, multiple platforms with language conversions), you **MUST** use the incremental platform migration approach described in Step 5. Attempting to migrate all platforms simultaneously for large plugins leads to:
- Overwhelming code changes that are difficult to review
- Compound errors across platforms that are hard to debug
- User frustration with long wait times between checkpoints
- High risk of needing to rework multiple platforms if approach needs adjustment

**Always assess complexity in Step 5 before starting migration work.**

### Pre-Conversion Analysis

**CRITICAL: Analyze the Cordova plugin first** before asking the user questions. Use the `cordova-capacitor-plugin-migration` skill to understand:

1. **Plugin structure and configuration** (`plugin.xml`)
   - Plugin ID, name, and version
   - Platform support (iOS, Android, web)
   - Native class names and package IDs
   - Required permissions and features
   - Dependencies and frameworks

2. **JavaScript API** (`www/*.js` files)
   - Public methods and their signatures
   - Parameter types and return values
   - Error handling patterns
   - Event listeners and callbacks

3. **Native implementations**
   - iOS: Objective-C or Swift files
   - Android: Java or Kotlin files
   - Native method signatures
   - Business logic and algorithms

### Requirements Extraction Strategy

**Extract as much information as possible from the Cordova plugin** before asking the user:

✅ **Auto-derive from Cordova plugin:**
- Plugin name → Capacitor plugin name (convert format)
- Plugin ID → Capacitor package ID
- Native class names → Capacitor class names
- Method signatures → TypeScript API definitions
- Permissions from `plugin.xml` → Capacitor permission strings
- Platform support → iOS/Android implementation needs
- Dependencies → Package.swift / build.gradle dependencies

❌ **Only ask the user when:**
- Ambiguous naming (multiple valid conversions)
- Missing configuration (author, license, repository)
- Language preference for conversion (Java→Kotlin, Objective-C→Swift)
- New features to add during conversion
- Deprecated APIs that need modern alternatives

### Conversion Workflow

#### Step 1: Analyze Cordova Plugin
```bash
# First, understand the existing plugin structure
# Use cordova-capacitor-plugin-migration skill to examine:
# - plugin.xml
# - www/*.js files
# - iOS native files (*.m, *.h, *.swift)
# - Android native files (*.java, *.kt)
```

#### Step 2: Derive Requirements
Extract and document:
- **Plugin identity**: name, ID, version, description
- **API surface**: methods, parameters, return types, events
- **Platform support**: iOS, Android, web implementations
- **Permissions**: camera, location, storage, etc.
- **Dependencies**: native frameworks, libraries
- **Language**: Current language (Java/Kotlin, Obj-C/Swift)

#### Step 3: Plan Conversion
Present to user:
```
Based on the Cordova plugin analysis:

Plugin Name: cordova-plugin-battery-status
Proposed Capacitor Name: @company/capacitor-battery-status
Package ID: com.example.batterystatus
Class Name: BatteryStatus

API Methods Found:
- getBatteryStatus() → Promise<BatteryInfo>
- startMonitoring() → void
- stopMonitoring() → void

Platforms: iOS (Swift), Android (Java)
Permissions: None required

Conversion Options:
1. Keep Java → Java (minimal changes)
2. Convert Java → Kotlin (recommended, modern)
3. Keep Swift → Swift (already modern)

Which conversion approach do you prefer?
```

#### Step 4: Scaffold Capacitor Plugin
Use gathered information with `npm init @capacitor/plugin`:
```bash
npm init @capacitor/plugin capacitor-battery-status -- \
  --name "@company/capacitor-battery-status" \
  --package-id "com.example.batterystatus" \
  --class-name "BatteryStatus" \
  --description "Access device battery level and charging status" \
  --author "Company Name <email@company.com>" \
  --license "MIT" \
  --repo "https://github.com/company/capacitor-battery-status" \
  --android-lang "kotlin"
```

#### Step 5: Assess Migration Complexity & Plan Approach

Before starting code migration, evaluate the plugin's complexity to determine the best migration strategy.

**Complexity Assessment Criteria:**

- **Lines of Code**: Total LOC across all platforms
- **Number of Methods**: Public API surface area
- **Platform Support**: iOS + Android + Web vs. single platform
- **Native Dependencies**: External frameworks, libraries
- **Language Conversions**: Objective-C→Swift, Java→Kotlin
- **Hook Complexity**: Number and complexity of hooks
- **Business Logic Complexity**: Simple CRUD vs. complex algorithms

**Migration Strategies:**

**🟢 Simple Plugins (Migrate All Platforms Together)**

Use when:
- ✅ < 500 total lines of code
- ✅ < 5 public API methods
- ✅ Minimal native dependencies
- ✅ No language conversions needed
- ✅ No complex hooks

**Approach:**
1. Migrate TypeScript API
2. Migrate iOS implementation
3. Migrate Android implementation
4. Verify all platforms together
5. Test with example-app

**Estimated Time:** 2-4 hours

---

**🟡 Moderate Plugins (Phased Migration Recommended)**

Use when:
- ⚠️ 500-2000 lines of code
- ⚠️ 5-15 public API methods
- ⚠️ Some native dependencies
- ⚠️ Language conversion required
- ⚠️ Some hooks to migrate

**Approach:**
1. Migrate TypeScript API (foundation for all platforms)
2. **Choose one platform to complete first** (iOS or Android)
3. Verify that platform builds and works
4. **Pause for user inspection and approval**
5. Migrate second platform
6. Verify second platform
7. Implement web fallback
8. Final integration testing

**Estimated Time:** 4-8 hours (with checkpoints)

---

**🔴 Complex Plugins (MUST Use Incremental Platform Migration)**

Use when:
- ❌ > 2000 lines of code
- ❌ > 15 public API methods
- ❌ Heavy native dependencies
- ❌ Multiple language conversions
- ❌ Complex hooks (Tier 3 blockers)
- ❌ Platform-specific business logic

**⚠️ MANDATORY APPROACH: Incremental Platform Migration**

For complex plugins, attempting to migrate everything at once leads to:
- Overwhelming code changes
- Difficult debugging across platforms
- High risk of missing issues
- User frustration with long wait times
- Compound errors that are hard to isolate

**Required Workflow:**

```markdown
## Phase 1: TypeScript API Layer (Foundation)
1. Scaffold plugin structure
2. Create TypeScript definitions for ALL methods
3. Implement web stub/mock implementation
4. Verify TypeScript compiles: `npm run verify:web`
5. **CHECKPOINT: User approval before native code**

## Phase 2: iOS Implementation (First Platform)
**Why iOS first?**
- Swift is more modern and type-safe than Java
- Xcode provides better error messages
- iOS APIs are generally more consistent
- CocoaPods/SPM dependency resolution is more reliable

**Steps:**
1. Migrate iOS native code ONLY
2. Convert Objective-C → Swift if needed
3. Add iOS dependencies to Package.swift
4. Verify iOS builds: `npm run verify:ios`
5. Update example-app with iOS test cases
6. Test on iOS simulator
7. Test on real iOS device (if available)
8. **CHECKPOINT: Demonstrate working iOS implementation to user**
9. **User approval required before proceeding to Android**

**Deliverable:**
- ✅ Fully functional iOS implementation
- ✅ Verified with example-app on device
- ✅ All iOS methods working correctly
- ✅ User inspected and approved

## Phase 3: Android Implementation (Second Platform)
**Only proceed after iOS approval**

**Steps:**
1. Migrate Android native code ONLY
2. Convert Java → Kotlin if needed
3. Add Android dependencies to build.gradle
4. Verify Android builds: `npm run verify:android`
5. Update example-app with Android test cases
6. Test on Android emulator
7. Test on real Android device (if available)
8. **CHECKPOINT: Demonstrate working Android implementation to user**
9. **User approval required before finalization**

**Deliverable:**
- ✅ Fully functional Android implementation
- ✅ Verified with example-app on device
- ✅ All Android methods working correctly
- ✅ Platform parity with iOS verified
- ✅ User inspected and approved

## Phase 4: Web Implementation & Documentation (Final)
**Only after both native platforms approved**

**Steps:**
1. Enhance web implementation (if applicable)
2. Update README with installation instructions
3. Document platform-specific setup requirements
4. Document hook migration steps (if applicable)
5. Run full verification: `npm run verify`
6. Final integration testing
7. **CHECKPOINT: Final user review**

**Deliverable:**
- ✅ Complete plugin ready for use
- ✅ Comprehensive documentation
- ✅ All platforms tested and verified
```

**Why Incremental Migration is Critical for Complex Plugins:**

✅ **Risk Mitigation**: Issues are isolated to one platform at a time
✅ **User Confidence**: User sees working progress and can provide feedback early
✅ **Debugging**: Easier to identify which platform has issues
✅ **Course Correction**: User can request changes before all work is done
✅ **Quality**: Each platform receives full attention and testing
✅ **Avoiding Rework**: If approach needs adjustment, only one platform needs changes

**Estimated Time:** 8-20+ hours (with multiple checkpoints)

---

**Decision Matrix:**

| Plugin Characteristic | Simple 🟢 | Moderate 🟡 | Complex 🔴 |
|-----------------------|-----------|-------------|------------|
| Total LOC | < 500 | 500-2000 | > 2000 |
| API Methods | < 5 | 5-15 | > 15 |
| Native Dependencies | None/Few | Some | Many |
| Language Conversions | None | One | Multiple |
| Hooks | None | Convertible | Blockers |
| Migration Approach | All-at-once | Phased | **Incremental** |
| User Checkpoints | 1 (final) | 2-3 | **4-5 (required)** |

---

**Recommended Platform Order:**

1. **TypeScript API** (always first - foundation)
2. **iOS** (second - cleaner APIs, better tooling)
3. **Android** (third - after iOS validates approach)
4. **Web** (last - often simplest or mock implementation)

**Alternative: Android-First Approach**

Use Android-first when:
- Plugin is Android-only
- Team is more familiar with Android
- iOS version is very simple
- Android has more complex logic

---

#### Step 6: Migrate Code (Platform-by-Platform)

**For Simple Plugins:**
Port all platforms together with these priorities:

1. **TypeScript API** - Convert Cordova JS API to Capacitor definitions
   - `exec(success, error, "PluginName", "methodName", [args])` → `async methodName(args): Promise<Result>`
   - Callbacks → Promises
   - Events → `addListener()` pattern

2. **iOS Native** - Port Objective-C/Swift to modern Swift
   - `CDVPlugin` → `CAPPlugin` / `CAPBridgedPlugin`
   - `CDVPluginResult` → `call.resolve()` / `call.reject()`
   - `-[methodName:]` → `@objc func methodName(_ call: CAPPluginCall)`

3. **Android Native** - Port Java/Kotlin to Capacitor pattern
   - `CordovaPlugin` → `Plugin` with `@CapacitorPlugin`
   - `CallbackContext` → `PluginCall`
   - `execute()` method → `@PluginMethod` annotations
   - Language conversion if needed (Java → Kotlin)

**For Moderate/Complex Plugins:**
Follow the incremental platform migration approach described in Step 5, migrating one platform completely before starting the next.

#### Step 7: CRITICAL - Run Verification Scripts

**MANDATORY: Always run verify scripts after conversion**, especially when converting languages:

```bash
# Auto-format all code
npm run fmt

# Verify all platforms build successfully
npm run verify

# This ensures:
# - TypeScript compiles correctly
# - iOS Swift builds without errors
# - Android Kotlin/Java builds without errors
# - Language conversions are syntactically correct
```

**Why this is critical:**
- ❌ Java→Kotlin conversions may have syntax errors
- ❌ Objective-C→Swift conversions need null-safety fixes
- ❌ Cordova→Capacitor API changes may break builds
- ✅ `verify` catches these issues immediately
- ✅ Running early prevents cascading errors

**Run verify at these checkpoints:**

**For Simple Plugins (all-at-once migration):**
1. After initial scaffolding
2. After porting TypeScript API
3. After porting iOS native code
4. After porting Android native code
5. After any language conversion
6. Before testing with example-app

**For Moderate/Complex Plugins (incremental migration):**
1. After initial scaffolding → `npm run verify:web`
2. After porting TypeScript API → `npm run verify:web`
3. After porting iOS native code → `npm run verify:ios`
4. **Before user checkpoint** → `npm run verify:ios` + test with example-app
5. After porting Android native code → `npm run verify:android`
6. **Before user checkpoint** → `npm run verify:android` + test with example-app
7. After web implementation → `npm run verify` (all platforms)
8. **Before final delivery** → Full integration testing

#### Step 8: Implement Comprehensive Example App Tests

**MANDATORY: Implement test functionality for ALL converted features** in the plugin's `example-app` project.

This serves dual purposes:
1. ✅ Validates the conversion worked correctly
2. ✅ Demonstrates proper Capacitor usage patterns to users

**Implementation Requirements:**

```typescript
// example-app/src/js/example.js (or similar)
import { BatteryStatus } from '@company/capacitor-battery-status';

// Test EVERY method from the original Cordova plugin
async function testAllFeatures() {
  console.log('=== Testing Converted Plugin Features ===');

  // Feature 1: getBatteryStatus()
  try {
    const status = await BatteryStatus.getBatteryStatus();
    console.log('✅ getBatteryStatus():', status);
    displayResult('Battery Status', status);
  } catch (error) {
    console.error('❌ getBatteryStatus() failed:', error);
    displayError('Battery Status', error);
  }

  // Feature 2: startMonitoring()
  try {
    await BatteryStatus.startMonitoring();
    console.log('✅ startMonitoring() started');
    displayResult('Monitoring', { started: true });
  } catch (error) {
    console.error('❌ startMonitoring() failed:', error);
    displayError('Monitoring', error);
  }

  // Feature 3: Event listeners (if applicable)
  try {
    await BatteryStatus.addListener('batteryChange', (info) => {
      console.log('✅ batteryChange event:', info);
      displayResult('Battery Event', info);
    });
    console.log('✅ Event listener registered');
  } catch (error) {
    console.error('❌ Event listener failed:', error);
    displayError('Event Listener', error);
  }

  // Add test cases for ALL other methods...
}

// Create UI elements to trigger tests
function setupTestUI() {
  // Add buttons for each feature
  addTestButton('Get Battery Status', () => BatteryStatus.getBatteryStatus());
  addTestButton('Start Monitoring', () => BatteryStatus.startMonitoring());
  addTestButton('Stop Monitoring', () => BatteryStatus.stopMonitoring());

  // Add result display area
  createResultDisplay();
}

// Run tests on load
testAllFeatures();
setupTestUI();
```

**Build and test on platforms:**
```bash
cd example-app
npm install
npx cap sync

# Test on iOS
npx cap open ios
# Run in Xcode, interact with UI, check console logs

# Test on Android
npx cap open android
# Run in Android Studio, interact with UI, check Logcat
```

**Example App Test Checklist:**

For each Cordova plugin method:
- [ ] Create a test function in example-app
- [ ] Add UI button/trigger to invoke the method
- [ ] Display results in the UI (not just console)
- [ ] Test success cases
- [ ] Test error cases (missing params, permission denied)
- [ ] Add console logging for debugging
- [ ] Verify on both iOS and Android
- [ ] Test on real devices (not just simulators)
- [ ] Compare behavior to original Cordova plugin

**Why this is mandatory for conversions:**
- ❌ Without tests, you can't verify the conversion is complete
- ❌ Missing features may go unnoticed until production
- ✅ Demonstrates to users how to migrate their code
- ✅ Provides working reference implementation
- ✅ Catches API design issues early
- ✅ Validates platform parity (iOS vs Android)

#### Step 9: Validate Parity

**For Simple Plugins:**
Create a checklist comparing Cordova vs Capacitor after completing all platforms:

- [ ] All public methods ported
- [ ] All events/listeners migrated
- [ ] Permission handling equivalent
- [ ] Error messages consistent
- [ ] Platform-specific behavior preserved
- [ ] Edge cases handled
- [ ] **All features tested in example-app**
- [ ] **Example-app demonstrates usage of ALL converted methods**
- [ ] Example-app UI allows manual testing
- [ ] Example-app console logs show success/error for each feature
- [ ] Documentation updated
- [ ] **All verify scripts pass**
- [ ] Tested on real devices (not just simulators)
- [ ] Behavior matches original Cordova plugin

**For Moderate/Complex Plugins (Incremental Migration):**
Validate parity **incrementally at each checkpoint**:

**After iOS Implementation (Checkpoint 1):**
- [ ] All iOS methods ported and functional
- [ ] iOS permission handling equivalent
- [ ] iOS error messages consistent
- [ ] iOS platform-specific behavior preserved
- [ ] **iOS features tested in example-app on iOS device**
- [ ] `npm run verify:ios` passes
- [ ] iOS behavior matches original Cordova plugin
- [ ] **USER APPROVED BEFORE CONTINUING**

**After Android Implementation (Checkpoint 2):**
- [ ] All Android methods ported and functional
- [ ] Android permission handling equivalent
- [ ] Android error messages consistent
- [ ] Android platform-specific behavior preserved
- [ ] **Android features tested in example-app on Android device**
- [ ] `npm run verify:android` passes
- [ ] **Platform parity: iOS and Android behave consistently**
- [ ] Android behavior matches original Cordova plugin
- [ ] **USER APPROVED BEFORE CONTINUING**

**After Web Implementation (Final Checkpoint):**
- [ ] Web fallback/mock implementation complete
- [ ] All events/listeners migrated across all platforms
- [ ] Documentation updated with platform-specific notes
- [ ] Example-app UI demonstrates ALL methods on ALL platforms
- [ ] `npm run verify` (all platforms) passes
- [ ] Full integration testing complete
- [ ] **USER FINAL APPROVAL**

**Why Incremental Validation Matters:**
- ✅ Catches issues early when they're easier to fix
- ✅ User sees tangible progress and can provide feedback
- ✅ Reduces risk of compound errors across platforms
- ✅ Allows course correction before investing in next platform

### Common Cordova→Capacitor Mappings

| Cordova Pattern | Capacitor Pattern |
|----------------|-------------------|
| `exec(success, error, "Plugin", "method", [args])` | `await Plugin.method(args)` |
| `CDVPlugin` | `CAPPlugin` / `CAPBridgedPlugin` |
| `CDVPluginResult` | `call.resolve()` / `call.reject()` |
| `CallbackContext` | `PluginCall` |
| `plugin.xml` | `Package.swift` + `package.json` |
| `<feature name="Plugin">` | `@CapacitorPlugin(name = "Plugin")` |
| Callbacks | Promises |
| `window.cordova.plugins.X` | `import { X } from '@company/capacitor-x'` |

### Language Conversion Considerations

**Java → Kotlin:**
- Null safety (`String?` vs `String`)
- Extension functions vs static methods
- Data classes vs POJOs
- Coroutines vs callbacks (optional enhancement)
- **CRITICAL: Run `npm run verify:android` after conversion**

**Objective-C → Swift:**
- Optionals (`String?` vs `String`)
- Modern Swift APIs (async/await available)
- Memory management (ARC automatic)
- Nullability annotations no longer needed
- **CRITICAL: Run `npm run verify:ios` after conversion**

**Verification is non-negotiable when converting languages** - automated builds catch syntax errors that manual review might miss.

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

**Use the AskUserQuestion tool** to gather all required information interactively. Ask questions in batches of 2-4 to avoid overwhelming the user.

**Batch 1 - Plugin Identity (4 questions):**

Use AskUserQuestion with these questions:

1. **What is the plugin's purpose?**
   - Header: "Purpose"
   - Question: "What does this plugin do?"
   - Options: Provide 2-3 common examples based on context, plus "Other"
   - Description: This will be used for the plugin description

2. **What should the folder/directory be named?**
   - Header: "Folder Name"
   - Question: "What folder should the plugin be created in?"
   - Options: Suggest 2-3 based on purpose (e.g., `capacitor-battery`, `capacitor-device-info`)
   - Description: The plugin will be created in this subdirectory

3. **Is this for an organization or company?**
   - Header: "Organization"
   - Question: "Is this plugin part of an organization?"
   - Options:
     - "Yes, for my company" (description: "Will use @company npm scope")
     - "Yes, personal (@username)" (description: "Will use personal npm scope")
     - "No, unscoped" (description: "Plugin name without @ scope")
   - If "Yes", ask follow-up: "What is the organization/company name?"

4. **What is the base plugin name?**
   - Header: "Plugin Name"
   - Question: "What should the plugin be called?"
   - Options: Derive from purpose (e.g., "battery", "device-info", "scanner")
   - Description: **Avoid redundancy** - use short names without "plugin" suffix
   - Examples: `battery`, `device-info`, `scanner` (NOT `battery-plugin`)

**Batch 2 - Technical Details (4 questions):**

Use AskUserQuestion with these questions:

5. **What is the class name?**
   - Header: "Class Name"
   - Question: "What should the native class be named?"
   - Options: Derive from plugin name in PascalCase (e.g., "Battery", "DeviceInfo", "Scanner")
   - Description: **CRITICAL**: Do NOT include "Plugin" suffix - the generator adds it automatically
   - ❌ Bad: `BatteryPlugin` → creates `BatteryPluginPlugin.swift`
   - ✅ Good: `Battery` → creates `BatteryPlugin.swift`

6. **What is the package ID?**
   - Header: "Package ID"
   - Question: "What is the reverse-DNS package identifier?"
   - Options: Suggest based on company/plugin name (e.g., `com.acme.battery`, `com.mycompany.deviceinfo`)
   - Description: Format: `com.{company}.{pluginname}` (lowercase, no hyphens)

7. **What Android language should be used?**
   - Header: "Android Lang"
   - Question: "Which language should be used for Android implementation?"
   - Options:
     - "Kotlin" (description: "Modern, recommended for new plugins")
     - "Java" (description: "Traditional, wider compatibility")
   - **Recommendation**: Kotlin (modern, null-safe, concise)

8. **What license should be used?**
   - Header: "License"
   - Question: "Which license should the plugin use?"
   - Options:
     - "MIT" (description: "Permissive, most common")
     - "Apache-2.0" (description: "Permissive with patent grant")
     - "BSD-3-Clause" (description: "Permissive BSD license")
     - "ISC" (description: "Simplified MIT alternative")

9. **Additional metadata:**
   - Ask for author information: "Name <email@company.com>"
   - Ask for repository URL: "https://github.com/company/plugin-name"
   - These can be text inputs or suggested based on git config

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
  --repo "{repo-url}" \
  --android-lang "{kotlin|java}"
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
- Android language: `kotlin`

**Generated Command:**
```bash
npm init @capacitor/plugin capacitor-battery -- \
  --name "@acme/capacitor-battery" \
  --package-id "com.acme.battery" \
  --class-name "Battery" \
  --description "Access device battery level and charging status" \
  --author "Jane Developer <jane@acme.com>" \
  --license "MIT" \
  --repo "https://github.com/acme/capacitor-battery" \
  --android-lang "kotlin"
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
  --repo "https://github.com/acme/capacitor-battery" \
  --android-lang "kotlin"

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

Before writing code, understand what the plugin needs to accomplish. **Use AskUserQuestion for questions with clear options** (platform support, permission types, etc.), and ask open-ended questions in conversational text for technical details.

#### Functional Requirements

**Use AskUserQuestion for:**

1. **What platforms need to be supported?**
   - Header: "Platforms"
   - Question: "Which platforms should this plugin support?"
   - Options:
     - "iOS and Android" (description: "Full native support on both platforms")
     - "iOS only" (description: "iOS native, Android falls back to web")
     - "Android only" (description: "Android native, iOS falls back to web")
   - multiSelect: Consider allowing both to be selected if incremental implementation

2. **What permissions are required?**
   - Header: "Permissions"
   - Question: "What platform permissions does this plugin need?"
   - multiSelect: true
   - Options based on common permissions:
     - "Camera" (description: "Camera access - Info.plist + AndroidManifest")
     - "Location" (description: "GPS/location services")
     - "Photos/Gallery" (description: "Access to photo library")
     - "Microphone" (description: "Audio recording")
     - "None" (description: "No special permissions needed")

**Ask conversationally:**

3. **What native capability does this plugin expose?**
   - Example: "Access device battery status", "Scan QR codes", "Encrypt local data"
   - This helps understand the core functionality

4. **What data flows between native and web?**
   - Input parameters (types, validation requirements)
   - Return values (success data, error cases)
   - Events or callbacks needed?

#### Technical Constraints

**Ask conversationally:**

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
  --repo "https://github.com/company/plugin-name" \
  --android-lang "kotlin"

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
| **"invalid option: --android-lang undefined"** | Add `--android-lang "kotlin"` or `--android-lang "java"` to the command |
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
     --repo "https://github.com/..." \
     --android-lang "kotlin"
   ```

2. **Missing --android-lang parameter**:
   If you see "invalid option: --android-lang undefined: Must be either 'kotlin' or 'java'":
   ```bash
   # The --android-lang parameter is REQUIRED
   npm init @capacitor/plugin my-plugin -- \
     --name "@company/plugin" \
     --package-id "com.company.plugin" \
     --class-name "MyPlugin" \
     --description "Description" \
     --author "Name <email>" \
     --license "MIT" \
     --repo "https://github.com/..." \
     --android-lang "kotlin"  # ← This is required!
   ```
   **Recommendation**: Use `"kotlin"` for new plugins (modern, null-safe, recommended by Capacitor team)

3. **Enable debug logging**:
   ```typescript
   // iOS: Check Xcode console
   // Android: Check Logcat
   ```

4. **Test platforms independently**:
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
