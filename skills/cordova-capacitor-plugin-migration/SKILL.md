---
name: cordova-capacitor-plugin-migration
description: >-
  Analyzes Cordova plugins for conversion to Capacitor. Examines plugin.xml,
  JavaScript bridge code, iOS (Objective-C/Swift), and Android (Java/Kotlin)
  implementations. Identifies migration complexity, maps Cordova APIs to
  Capacitor equivalents, highlights unsupported patterns, and assesses
  migration feasibility. Use when migrating Cordova plugins, understanding
  plugin architecture for conversion, assessing migration effort, identifying
  migration blockers, or planning Capacitor plugin development from existing
  Cordova plugins.
---

# Cordova to Capacitor Plugin Migration Analyzer

Analyzes Cordova plugins to understand their structure and plan their conversion to Capacitor. Provides architecture analysis, migration complexity assessment, Cordova-to-Capacitor API mappings, and identifies unsupported patterns that block or complicate migration.

## Contents

- [Purpose](#purpose)
- [When to Use This Skill](#when-to-use-this-skill)
- [When NOT to Use This Skill](#when-not-to-use-this-skill)
- [Analysis Approach](#analysis-approach)
- [Migration Complexity Assessment](#migration-complexity-assessment)
- [Plugin Structure Reference](#plugin-structure-reference)
- [Unsupported Patterns and Migration Blockers](#unsupported-patterns-and-migration-blockers)
- [Migration Analysis Output Format](#migration-analysis-output-format)
- [Migration Completion & Documentation Cleanup](#migration-completion--documentation-cleanup)
- [Migration Analysis Checklist](#migration-analysis-checklist)
- [Tips for Migration Analysis](#tips-for-migration-analysis)
- [Limitations](#limitations)
- [Additional Resources](#additional-resources)

---

## Purpose

This skill analyzes Cordova plugins to prepare them for migration to Capacitor. It identifies key patterns, assesses migration complexity, maps Cordova concepts to their Capacitor equivalents, and **flags Cordova-specific features that cannot be converted** or require significant workarounds.

**Primary Workflow:** The analysis output is designed to feed directly into the `capacitor-plugin-dev` skill for building the Capacitor plugin. The analysis provides all necessary information for plugin development without requiring repeated inspection of the original Cordova code.

---

## When to Use This Skill

Use this skill when you need to:

- ✅ Plan a Cordova to Capacitor plugin migration
- ✅ Understand Cordova plugin structure for conversion purposes
- ✅ Assess migration complexity and effort estimation
- ✅ Identify platform-specific migration challenges
- ✅ Map Cordova APIs to Capacitor equivalents
- ✅ Detect unsupported patterns and migration blockers
- ✅ Understand what code needs to change for Capacitor compatibility
- ✅ Evaluate migration feasibility before starting work

---

## When NOT to Use This Skill

This skill is focused on migration analysis, NOT:

- ❌ Creating new Capacitor plugins from scratch (use capacitor-plugin-dev skill)
- ❌ General Cordova development without migration intent
- ❌ Debugging runtime issues or crashes
- ❌ Migrating entire Cordova apps (this is plugin-specific only)
- ❌ Performing the actual code refactoring (analysis only)

For creating new Capacitor plugins from scratch, use the capacitor-plugin-dev skill. For general development assistance, request it separately.

---

## Analysis Approach

### Progressive Disclosure for Migration

When analyzing a plugin for migration, follow this progression:

**1. Initial Analysis (Default Response)**
- Plugin purpose and functionality
- Supported platforms (iOS, Android, web)
- Migration complexity assessment (Simple, Moderate, Complex)
- Critical unsupported patterns that block migration
- Cordova plugin architecture summary (methods, classes, flow)
- Capacitor plugin mapping (how it will translate)
- ASCII art visualization of architecture transformation
- Migration roadmap
- **NOTE:** Do NOT include code snippets unless specifically requested

**2. Detailed Code Examples (On Request Only)**
- Before/after code comparisons
- Specific method conversion examples
- Platform-specific code migration details
- Implementation code snippets

See **[reference/api-mappings.md](reference/api-mappings.md)** for detailed Cordova to Capacitor code mappings.

See **[reference/migration-patterns.md](reference/migration-patterns.md)** for common migration patterns and examples.

**3. Deep Dive Analysis (On Request Only)**
- Method-by-method migration strategy
- Line-by-line code walkthrough
- Platform-specific migration nuances
- Required workarounds for unsupported features

### Migration Analysis Flow

```
1. Read plugin.xml → Identify unsupported config patterns
2. Analyze third-party dependencies → Map CocoaPods, Gradle, and manual dependencies
3. Analyze www/ directory → Map JavaScript API to TypeScript
4. Examine iOS src/ → Map CDVPlugin to CAPPlugin patterns
5. Examine Android src/ → Map CordovaPlugin to Plugin/Bridge patterns
6. Assess complexity → Flag blockers and assess feasibility
7. Generate architecture mapping → Visualize Cordova → Capacitor transformation
8. Provide migration roadmap → Prioritize conversion steps
9. Output analysis → Ready for capacitor-plugin-dev skill consumption
```

**Default Workflow:**
Unless otherwise specified, the analysis is intended to feed into the `capacitor-plugin-dev` skill for implementation. The output provides all necessary architectural information, API mappings, and migration requirements without code snippets.

---

## Migration Complexity Assessment

**Simple Migration**
- Basic exec() calls with simple arguments
- Standard success/error callbacks
- Minimal plugin.xml configuration
- No unsupported patterns
- Standard iOS/Android APIs

**Moderate Migration**
- Complex data structures in arguments
- Multiple platform-specific implementations
- Framework dependencies that need remapping
- Some config-file modifications (need workarounds)
- Async/Promise patterns need refactoring

**Complex Migration**
- Heavy use of plugin.xml hooks or edit-config
- Extensive config-file modifications
- Dependencies on other Cordova plugins
- Platform-specific hacks or workarounds
- Unsupported Cordova APIs without Capacitor equivalents

---

## Plugin Structure Reference

### Standard Cordova Plugin Layout

```
my-plugin/
├── plugin.xml           # Plugin manifest and configuration
├── www/
│   └── MyPlugin.js      # JavaScript interface
├── src/
│   ├── ios/
│   │   └── MyPlugin.{h,m,swift}     # iOS implementation
│   └── android/
│       └── MyPlugin.java             # Android implementation
└── package.json         # NPM metadata
```

### Key Files to Analyze

**plugin.xml**
- Plugin ID, version, description
- Platform declarations (`<platform name="ios|android">`)
- Source file mappings (`<source-file>`, `<header-file>`)
- Config file modifications (`<config-file>`)
- Dependencies and frameworks

**www/*.js (JavaScript Layer)**
- Public API methods
- `cordova.exec()` bridge calls
- Success/error callback handling
- Parameter serialization

**src/ios/*.{h,m,swift} (iOS Layer)**
- CDVPlugin subclass
- Method implementations matching JS actions
- CDVPluginResult responses
- iOS-specific APIs and frameworks

**src/android/*.java (Android Layer)**
- CordovaPlugin subclass
- execute() method with action routing
- CallbackContext responses
- Android-specific APIs and permissions

---

## Unsupported Patterns and Migration Blockers

**CRITICAL:** Capacitor has a fundamentally different architecture than Cordova. The following patterns **cannot** be directly converted and require workarounds or manual configuration.

### Quick Reference Table

| Cordova Feature | Capacitor Status | Workaround |
|----------------|------------------|------------|
| `<config-file>` modifications | ❌ Not supported | Manual native project configuration required |
| `<edit-config>` | ❌ Not supported | Manual native project configuration required |
| Hooks (`<hook>`) | ❌ Not supported | Use npm scripts, Capacitor hooks, or manual steps |
| `<js-module runs="true">` | ❌ Not supported | Move to plugin initialization code |
| `clobbers` target | ⚠️ Different pattern | Use Capacitor's `registerPlugin()` |
| `merges` target | ⚠️ Different pattern | Use Capacitor's `registerPlugin()` |
| `<dependency>` on other plugins | ⚠️ Different | Use npm dependencies + manual checks |
| `<preference>` tags | ⚠️ Different | Use Capacitor config or manual iOS/Android configs |
| `<resource-file>` | ⚠️ Different | Manual native project resource management |
| `<framework>` injection | ⚠️ Partially supported | Manual Podfile/gradle configuration |
| Permissions | ⚠️ Must document | Document in README, use runtime permission APIs |

### Detailed Unsupported Patterns

See **[reference/unsupported-patterns.md](reference/unsupported-patterns.md)** for:
- Detailed explanations of each unsupported pattern
- Why each pattern fails in Capacitor
- Specific workarounds and migration strategies
- Examples and code snippets
- When to flag patterns as migration blockers

### Third-Party Dependencies

See **[reference/dependency-migration.md](reference/dependency-migration.md)** for:
- Identifying dependencies in Cordova (CocoaPods, Gradle, frameworks)
- iOS dependencies (System Frameworks, CocoaPods, SPM, custom frameworks)
- Android dependencies (Gradle, AAR/JAR, Maven repositories)
- Migration strategies for each dependency type
- When to flag dependencies as migration blockers
- Complete analysis templates and examples

### Cordova Hooks Migration

See **[reference/hooks-migration.md](reference/hooks-migration.md)** for:
- Three-tiered approach to hook migration (Tier 1/2/3)
- Available Capacitor hooks
- npm lifecycle script alternatives
- Migration blocker identification
- Hook analysis workflow and templates
- Complete examples for each tier

**Quick Summary:**
- **Tier 1 ✅**: Convertible to Capacitor hooks (`capacitor:sync:end`, etc.)
- **Tier 2 ⚠️**: Convertible to npm scripts (`postinstall`, etc.) or manual steps
- **Tier 3 ❌**: Migration blockers (interactive hooks, Cordova-specific operations)

---

## Migration Analysis Output Format

When analyzing a plugin for migration, structure your response as follows:

### 1. Migration Overview Section

```markdown
## Migration Overview

**Plugin Name:** [Plugin name from plugin.xml]
**Plugin ID:** [Cordova plugin ID]
**Purpose:** [Brief description of what the plugin does]
**Platforms:** [iOS, Android, web]
**Migration Complexity:** [Simple / Moderate / Complex]
**Migration Feasibility:** [Straightforward / Requires Workarounds / Challenging]
```

### 2. Unsupported Patterns Detection

```markdown
## ⚠️ Migration Blockers & Unsupported Patterns

[IF NONE FOUND:]
✅ No blocking unsupported patterns detected. This plugin uses standard Cordova APIs that have Capacitor equivalents.

[IF FOUND:]
❌ **Critical Issues:**
1. **config-file modifications** (plugin.xml:45-52)
   - Modifies AndroidManifest.xml
   - Requires manual native configuration after migration

2. **Installation hooks - Migration Blocker** (plugin.xml:12)
   - Uses interactive setup hook that cannot be converted
   - See detailed hook analysis below

⚠️ **Warnings:**
1. **Framework dependencies** (plugin.xml:78-82)
   - Requires manual Podfile/gradle configuration

2. **Hooks - Convertible** (plugin.xml:38, 45)
   - Uses convertible hooks (see detailed analysis below)
   - Migration strategy: Capacitor hooks + npm scripts
```

### 3. Third-Party Dependencies Analysis

**Include this section for ALL plugins that have `<framework>` tags or custom dependencies in plugin.xml.**

Analyze and document migration strategy for each dependency:

```markdown
## 📦 Third-Party Dependencies Analysis

### iOS Dependencies

#### System Frameworks
- ✅ **CoreLocation.framework** - Automatic linking, no action required
- ✅ **MapKit.framework** - Automatic linking, no action required

#### CocoaPods Dependencies
- ⚠️ **GoogleMaps (~> 3.5.0)**
  - Migration Strategy: Direct migration with version update to 8.3.0
  - Complexity: Moderate (API changes in 4.x+)
  - Action: Add to Podfile

- ❌ **AFNetworking (~> 2.0)** - **MIGRATION BLOCKER**
  - Issue: Abandoned library, no Swift 5 support
  - Solution: Replace with Alamofire 5.x or native URLSession
  - Impact: High effort (2-3 days to rewrite networking)

### Android Dependencies

#### Gradle Dependencies
- ✅ **com.google.android.gms:play-services-maps:18.0.0**
  - Migration Strategy: Direct migration (update to 18.2.0)
  - Complexity: Low
  - Action: Add to build.gradle

- ❌ **libs/proprietary-sdk.aar** - **MIGRATION BLOCKER**
  - Issue: Not publicly available, uses Support Library
  - Solution: Contact vendor for AndroidX version
  - Impact: Critical feature unavailable without resolution

## 📋 Dependency Migration Summary

**Total Dependencies:** [Number]
- ✅ **Direct Migration:** [Number]
- ⚠️ **Requires Workarounds:** [Number]
- ❌ **Migration Blockers:** [Number]

**Overall Assessment:** [Straightforward / Moderate / Blocked]

**Critical Actions:**
1. [Action required before migration can proceed]
```

See **[reference/dependency-migration.md](reference/dependency-migration.md)** for:
- Complete dependency identification guide
- iOS dependencies (CocoaPods, SPM, Frameworks)
- Android dependencies (Gradle, AAR/JAR, Maven repos)
- Migration strategies for each dependency type
- When to flag dependencies as blockers
- Detailed analysis templates

### 4. Cordova Hooks Analysis (If Applicable)

**Include this section ONLY if the plugin has `<hook>` tags in plugin.xml.**

Provide a detailed analysis of each hook using the three-tiered approach from **[reference/hooks-migration.md](reference/hooks-migration.md)**.

### 5. Architecture Summary

```markdown
## Cordova Plugin Architecture

**JavaScript API:**
- Method: `methodName(arg1, arg2, success, error)`
- Bridge: Uses `cordova.exec()` with callbacks
- Arguments: Positional array-based

**iOS Implementation:**
- Class: `MyPlugin` (Objective-C/Swift)
- Base: Extends `CDVPlugin`
- Methods: `-(void)methodName:(CDVInvokedUrlCommand*)command`
- Response: `CDVPluginResult` sent via commandDelegate

**Android Implementation:**
- Class: `MyPlugin` (Java/Kotlin)
- Base: Extends `CordovaPlugin`
- Router: Single `execute()` method routes actions by string
- Response: `CallbackContext.success/error()`

## Capacitor Plugin Architecture (Target)

**TypeScript API:**
- Interface: Typed method signatures in `definitions.ts`
- Bridge: `registerPlugin()` with Promise-based API
- Arguments: Named object parameters

**iOS Implementation:**
- Class: `MyPlugin` (Swift preferred)
- Base: Extends `CAPPlugin`
- Methods: `@objc func methodName(_ call: CAPPluginCall)`
- Response: `call.resolve()` / `call.reject()`

**Android Implementation:**
- Class: `MyPlugin` (Kotlin preferred)
- Base: Extends `Plugin`
- Methods: Individual `@PluginMethod` annotated functions
- Response: `call.resolve()` / `call.reject()`
```

### 6. Architecture Transformation Visualization

Provide an ASCII diagram showing the Cordova → Capacitor transformation. See **[reference/example-analysis.md](reference/example-analysis.md)** for a complete example.

### 7. Migration Roadmap

```markdown
## Migration Roadmap

### Phase 1: TypeScript API Layer
- [ ] Create `src/definitions.ts` with TypeScript interfaces
- [ ] Create `src/web.ts` with web implementation
- [ ] Convert callbacks → Promises
- [ ] Map exec() calls → typed methods

### Phase 2: iOS Native Layer
- [ ] Convert Objective-C → Swift (recommended)
- [ ] Change CDVPlugin → CAPPlugin
- [ ] Update method signatures for CAPPluginCall
- [ ] Replace CDVPluginResult with call.resolve()
- [ ] Add @objc decorators

### Phase 3: Android Native Layer
- [ ] Convert Java → Kotlin (recommended)
- [ ] Change CordovaPlugin → Plugin
- [ ] Add @CapacitorPlugin annotation
- [ ] Convert execute() router → @PluginMethod annotations
- [ ] Update CallbackContext → PluginCall

### Phase 4: Configuration & Documentation
- [ ] Document manual native configuration steps
- [ ] Create package.json with Capacitor metadata
- [ ] Remove plugin.xml
- [ ] Update README with setup instructions
- [ ] Add TypeScript typings

### Phase 5: Migration Completion & Cleanup
- [ ] Consolidate all migration documentation into single MIGRATION.md
- [ ] Remove intermediate .md files (status, TODO, implementation notes)
- [ ] Archive Cordova source files if needed
- [ ] Final testing and validation
- [ ] Update plugin README with migration summary
```

### 8. Next Steps

```markdown
## Next Steps

This analysis is ready to feed into the **capacitor-plugin-dev** skill for implementation.

**Recommended Workflow:**

**For Simple/Moderate Plugins:**
1. Review migration blockers and plan workarounds
2. Use `capacitor-plugin-dev` skill to scaffold the Capacitor plugin
3. Implement TypeScript API based on the mapping above
4. Implement native iOS/Android code following the architecture transformation
5. Document manual configuration steps for users

**For Complex Plugins (RECOMMENDED):**
1. Review migration blockers and plan workarounds
2. Use `capacitor-plugin-dev` skill to assess complexity (Step 5)
3. Follow **incremental platform migration approach**:
   - Phase 1: TypeScript API layer → User checkpoint
   - Phase 2: iOS implementation → User inspection and approval
   - Phase 3: Android implementation → User inspection and approval
   - Phase 4: Web implementation → Final review
   - Phase 5: Consolidate documentation and cleanup intermediate files
4. Document manual configuration steps for users

**⚠️ Complex Plugin Indicators:**
- > 2000 lines of code
- > 15 public API methods
- Multiple language conversions needed
- Complex hooks (Tier 3 blockers)
- Heavy native dependencies

**Why Incremental Migration:**
For complex plugins, migrating one platform at a time allows you to:
- ✅ Validate approach with working iOS implementation before Android
- ✅ Get user feedback early and adjust if needed
- ✅ Debug issues in isolation per platform
- ✅ Reduce risk of compound errors
- ✅ Demonstrate tangible progress to the user

**For more details, you can request:**
- "Show me code examples for [specific method]"
- "Explain the iOS migration in detail"
- "What does the Android implementation look like?"
- "Walk through the conversion of [feature]"
```

For a complete example analysis, see **[reference/example-analysis.md](reference/example-analysis.md)**.

---

## Migration Completion & Documentation Cleanup

After completing the plugin migration, consolidate all intermediate documentation into a single `MIGRATION.md` file at the plugin root and remove temporary documentation files.

### Files to Clean Up

During migration, various .md files may be created:
- Migration status files (`MIGRATION_STATUS.md`, `CONVERSION_STATUS.md`)
- Implementation TODO lists (`IMPLEMENTATION_TODO.md`, `iOS_TODO.md`, `ANDROID_TODO.md`)
- Platform-specific notes (`IOS_NOTES.md`, `ANDROID_NOTES.md`)
- API mapping documents (`API_MAPPING.md`)
- Blocker analysis files (`BLOCKERS.md`, `UNSUPPORTED_PATTERNS.md`)

### Consolidated MIGRATION.md Structure

Create a single `MIGRATION.md` at the plugin root with:

- **Overview**: Original plugin, new package name, migration date, complexity
- **What Changed**: API changes, breaking changes, platform-specific changes
- **Migration Blockers & Workarounds**: Resolved issues, known limitations
- **Manual Configuration Required**: iOS setup, Android setup, Capacitor config
- **Testing Notes**: Platform status, known issues, compatibility
- **References**: Original plugin, documentation, related issues

### Cleanup Process

1. **Collect information** from all intermediate .md files
2. **Consolidate** into the single MIGRATION.md using the template above
3. **Remove** all intermediate documentation files
4. **Update README.md** with migration summary and link to MIGRATION.md
5. **Archive Cordova source** (optional) or remove if in version control

### When to Perform Cleanup

Perform cleanup when:
- ✅ All platforms are implemented and tested
- ✅ Migration is functionally complete
- ✅ User has approved the final implementation
- ✅ No major rework is anticipated

Do NOT cleanup if:
- ❌ Migration is still in progress
- ❌ Only some platforms are complete
- ❌ Major issues remain unresolved
- ❌ User wants to keep detailed migration notes

---

## Migration Analysis Checklist

When analyzing a plugin for migration, verify:

**Blockers & Compatibility:**
- [ ] Check for `<config-file>` or `<edit-config>` in plugin.xml
- [ ] Check for hooks (`<hook>` tags)
  - [ ] If hooks found, analyze each hook script to understand behavior
  - [ ] Classify each hook as Tier 1 (Capacitor hooks), Tier 2 (custom scripts), or Tier 3 (blocker)
  - [ ] Document migration strategy for each hook (see [reference/hooks-migration.md](reference/hooks-migration.md))
  - [ ] Flag Tier 3 hooks as potential migration blockers
- [ ] Check for `<js-module runs="true">`
- [ ] Identify framework/dependency injection patterns
- [ ] Check for Cordova-specific APIs without Capacitor equivalents

**Third-Party Dependencies:**
- [ ] Identify all `<framework>` tags in plugin.xml
- [ ] **iOS Dependencies:**
  - [ ] Identify system frameworks (automatic linking)
  - [ ] Identify CocoaPods dependencies and versions
  - [ ] Check for custom/manual frameworks
  - [ ] Check for Swift Package Manager dependencies
  - [ ] Verify compatibility with current Swift/Xcode versions
  - [ ] Check for deprecated or abandoned pods
  - [ ] Flag incompatible dependencies as blockers
- [ ] **Android Dependencies:**
  - [ ] Identify Gradle dependencies and versions
  - [ ] Identify local AAR/JAR files
  - [ ] Check for custom Maven repositories
  - [ ] Verify AndroidX vs Support Library usage
  - [ ] Check compatibility with current Android SDK
  - [ ] Flag incompatible dependencies as blockers
- [ ] **For Each Dependency:**
  - [ ] Determine migration strategy (direct, update, replace, or blocker)
  - [ ] Document manual installation steps
  - [ ] Check for version conflicts with Capacitor core
  - [ ] Assess licensing and availability issues
- [ ] Document all dependencies in analysis output (see [reference/dependency-migration.md](reference/dependency-migration.md))

**Architecture Assessment:**
- [ ] Identify all JavaScript public API methods
- [ ] Map callback patterns to Promise equivalents
- [ ] Identify platform-specific implementations (iOS/Android)
- [ ] Check if iOS uses Objective-C (recommend Swift migration)
- [ ] Check if Android uses Java (recommend Kotlin migration)

**Migration Complexity:**
- [ ] Count number of public API methods
- [ ] Assess complexity of native implementations
- [ ] Identify external framework dependencies
- [ ] Check for platform-specific hacks or workarounds
- [ ] Estimate lines of code to convert

**Documentation Needs:**
- [ ] List required manual native configuration steps
- [ ] Document permission requirements
- [ ] List framework/dependency installation steps
- [ ] Identify breaking API changes for users
- [ ] Document hook migration strategy (Tier 1/2/3)

---

## Tips for Migration Analysis

1. **Start with plugin.xml** - Identify blockers immediately
2. **Analyze dependencies early** - Third-party deps can be major blockers
3. **Flag unsupported patterns early** - Set expectations upfront
4. **Assess complexity before deep dive** - Simple/Moderate/Complex
5. **Compare iOS and Android** - Ensure migration strategies align
6. **Check dependency availability** - Verify all deps are publicly accessible
7. **Consider language modernization** - Objective-C→Swift, Java→Kotlin
8. **Document all manual steps** - Critical for migration success (especially deps)
9. **Identify breaking changes** - Callbacks→Promises affects all consumers
10. **Check for Cordova plugin dependencies** - May need multiple migrations
11. **Analyze hooks with three-tier approach** - See [reference/hooks-migration.md](reference/hooks-migration.md)
12. **Test dependencies in isolation** - Verify compatibility before full migration

---

## Limitations

This skill focuses on migration analysis and planning, NOT:
- ❌ **Performing the actual code refactoring** - Use general development assistance for implementation
- ❌ **Creating new Capacitor plugins from scratch** - Use the capacitor-plugin-dev skill instead
- ❌ **Debugging runtime issues** - Provide error logs and request debugging help
- ❌ **Migrating entire Cordova apps** - This skill is plugin-specific only

**For Next Steps:**
- After analysis, use capacitor-plugin-dev skill for implementation guidance
- Request code review assistance for converted code
- Use general development tools for refactoring and testing

---

## Additional Resources

### Reference Documents

- **[reference/dependency-migration.md](reference/dependency-migration.md)** - Complete guide to migrating third-party dependencies (CocoaPods, SPM, Gradle, AAR/JAR)
- **[reference/hooks-migration.md](reference/hooks-migration.md)** - Complete hooks migration guide with three-tiered approach
- **[reference/api-mappings.md](reference/api-mappings.md)** - Detailed Cordova to Capacitor code mappings
- **[reference/unsupported-patterns.md](reference/unsupported-patterns.md)** - Deep dive on unsupported patterns and workarounds
- **[reference/example-analysis.md](reference/example-analysis.md)** - Complete example migration analysis
- **[reference/migration-patterns.md](reference/migration-patterns.md)** - Common migration patterns and best practices

### External Documentation

**Cordova:**
- [Cordova Plugin Reference](https://cordova.apache.org/docs/en/latest/guide/hybrid/plugins/)
- [iOS Plugin Development Guide](https://cordova.apache.org/docs/en/latest/guide/platforms/ios/plugin.html)
- [Android Plugin Development Guide](https://cordova.apache.org/docs/en/latest/guide/platforms/android/plugin.html)
- [plugin.xml Reference](https://cordova.apache.org/docs/en/latest/plugin_ref/spec.html)

**Capacitor:**
- [Capacitor Plugin Development Guide](https://capacitorjs.com/docs/plugins)
- [Capacitor Plugin API Reference](https://capacitorjs.com/docs/core-apis/plugin)
- [iOS Plugin Guide](https://capacitorjs.com/docs/plugins/ios)
- [Android Plugin Guide](https://capacitorjs.com/docs/plugins/android)
- [Web Plugin Guide](https://capacitorjs.com/docs/plugins/web)
- [Capacitor vs Cordova](https://capacitorjs.com/docs/cordova)

**Migration:**
- [Migrating from Cordova to Capacitor](https://capacitorjs.com/docs/cordova/migrating-from-cordova-to-capacitor)
- [Capacitor Community Plugins](https://github.com/capacitor-community) (Examples of migrated plugins)
