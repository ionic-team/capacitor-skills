# Third-Party Dependency Migration

This reference provides detailed guidance on identifying and migrating third-party dependencies from Cordova to Capacitor plugins.

## Contents

- [Overview](#overview)
- [Identifying Dependencies in Cordova](#identifying-dependencies-in-cordova)
- [iOS Dependencies](#ios-dependencies)
- [Android Dependencies](#android-dependencies)
- [Dependency Migration Strategies](#dependency-migration-strategies)
- [Migration Blockers](#migration-blockers)
- [Analysis Output Template](#analysis-output-template)

---

## Overview

Third-party dependencies are a critical aspect of plugin migration. Cordova automatically injects dependencies via plugin.xml, while Capacitor splits responsibility between the plugin author (who bundles deps inside the plugin package) and the consumer (who occasionally has to add things Gradle/CocoaPods cannot propagate, custom Maven repos, signed-binary copies, manifest/Info.plist entries).

**Key Differences:**

| Aspect | Cordova | Capacitor |
|--------|---------|-----------|
| **Declaration** | plugin.xml `<framework>` tags | Native dependency files (Podfile, build.gradle) |
| **Installation** | Automatic during plugin install | Plugin's own gradle/podspec for standard deps; consumer config for non-propagating items |
| **Version Management** | Fixed in plugin.xml | Plugin's gradle/podspec |
| **Dependency Type** | iOS: CocoaPods, Frameworks<br>Android: Gradle, JARs | iOS: CocoaPods, SPM<br>Android: Gradle |

---

## Ownership Model (READ THIS FIRST)

Before writing any "Add the following to your build.gradle" line, identify
**who** is supposed to add it. Capacitor plugins split into two distinct
audiences:

| Who | What they add | Where it goes |
| --- | --- | --- |
| **Plugin author** (you, producing the Capacitor port) | All standard `implementation '...'` Gradle lines, all `s.dependency '...'` CocoaPods lines, `vendored_frameworks` for shipped binaries | Plugin's own `android/build.gradle` and `<PluginName>.podspec`, bundled inside the npm package |
| **Consumer** (the app developer using the plugin) | Custom Maven repository URLs, manifest `<uses-permission>` and Info.plist `NSXxxUsageDescription`, Xcode capabilities (Apple Pay, Push, etc.), signed-binary local copies that cannot ship via npm | Host app's root `android/build.gradle` / `android/settings.gradle`, `android/app/src/main/AndroidManifest.xml`, `ios/App/App/Info.plist`, Xcode "Signing & Capabilities" |

The split exists because Gradle/CocoaPods propagate `implementation` /
`dependency` declarations transitively from a plugin module to its
consumer's app, but they **do not** propagate `repositories {}` blocks,
manifest entries, plist entries, or signing capabilities.

When the migrator emits `MIGRATION.md` or fills in `migration.warnings`, the
distinction must be explicit. Phrasing like *"add this to your app's
`android/app/build.gradle`"* is correct only for the consumer-side items
above. For everything else, the plugin's own gradle file owns it and the
consumer takes no action.

---

## Identifying Dependencies in Cordova

### Where to Look in plugin.xml

Dependencies are declared using `<framework>` tags:

```xml
<plugin id="com.example.myplugin">
    <platform name="ios">
        <!-- CocoaPods -->
        <framework src="GoogleMaps" type="podspec" spec="~> 3.5.0" />

        <!-- System Frameworks -->
        <framework src="CoreLocation.framework" />
        <framework src="MapKit.framework" />

        <!-- Podspec files -->
        <podspec>
            <config>
                <source url="https://github.com/CocoaPods/Specs.git"/>
            </config>
            <pods use-frameworks="true">
                <pod name="Alamofire" spec="~> 5.4" />
                <pod name="SwiftyJSON" spec="~> 5.0" />
            </pods>
        </podspec>
    </platform>

    <platform name="android">
        <!-- Gradle dependencies -->
        <framework src="com.google.android.gms:play-services-maps:18.0.0" />
        <framework src="com.squareup.okhttp3:okhttp:4.9.0" />

        <!-- Local AAR files -->
        <framework src="libs/custom-library.aar" custom="true" />
    </platform>
</plugin>
```

### Dependency Patterns to Identify

**iOS:**
1. **System Frameworks**: `.framework` suffix (e.g., `CoreLocation.framework`)
2. **CocoaPods**: `type="podspec"` or within `<podspec>` tags
3. **Manual Libraries**: Custom `.framework` or `.a` files
4. **Swift Package Manager**: Rare in Cordova, but may be referenced

**Android:**
1. **Gradle Dependencies**: Maven coordinates (e.g., `com.google.android.gms:play-services-maps:18.0.0`)
2. **Local Libraries**: Custom `.aar` or `.jar` files with `custom="true"`
3. **Repository URLs**: Custom Maven repositories

---

## iOS Dependencies

### System Frameworks

**Cordova Declaration:**
```xml
<framework src="CoreLocation.framework" />
<framework src="MapKit.framework" />
<framework src="AVFoundation.framework" />
<framework src="SwiftUICore.framework" weak="true" />
```

**Migration Strategy:** ✅ **Low Complexity**

System frameworks are built into iOS and don't require CocoaPods. In Capacitor:

**Option 1: Automatic Linking (Preferred)**
Most system frameworks are automatically linked by Xcode. No action needed.

**Weak-Linked Frameworks**

When the Cordova `<framework>` element has `weak="true"`, the framework
is optionally linked. This matters when the framework was introduced in
a newer iOS version than the plugin's deployment target, so the binary
needs to load on older OS versions where the framework isn't present.
The case that actually comes up on Capacitor today is
`SwiftUICore.framework` (introduced iOS 18) when the plugin still
supports iOS 15 (the Capacitor 8 minimum). Xcode 16+ implicitly links
SwiftUICore for anything using SwiftUI, so plugins that don't weak-link
crash at launch on iOS 17 and below.

Most of the legacy weak-link markers you'll see in old `plugin.xml`
files (`ImageIO`, `AudioToolbox`, `AVFoundation`, `CoreLocation`, etc.)
are available on every iOS version Capacitor supports, so the weak
attribute isn't doing anything useful. Carrying it forward is harmless
but optional.

Carry real weak links forward in the generated podspec:

```ruby
# Strong link (default)
s.framework  = 'CoreLocation', 'AVFoundation'

# Weak link (only needed when the framework's min iOS > the plugin's deployment target)
s.weak_framework = 'SwiftUICore'
```

The generator's input contract (`capacitor-plugin-generator/references/input-contract.md`)
does not currently distinguish strong vs weak framework links in
`dependencies.ios.system_frameworks`. Until the contract adds a
`weak_system_frameworks` field, surface weak links in `migration.notes`:

```yaml
dependencies:
  ios:
    system_frameworks: [CoreLocation, AVFoundation]

migration:
  notes:
    - "iOS weak-link: SwiftUICore.framework. Generator should emit s.weak_framework = 'SwiftUICore' in the podspec (framework is iOS 18+, plugin targets iOS 15)."
```

**Option 2: Manual Linking (If Needed)**
If the framework isn't automatically linked:
1. Open `ios/App/App.xcworkspace` in Xcode
2. Select the App target
3. Go to "Frameworks, Libraries, and Embedded Content"
4. Click "+" and add the framework

**Documentation Template:**
```markdown
### iOS System Frameworks

This plugin uses the following iOS system frameworks:
- CoreLocation.framework
- MapKit.framework
- AVFoundation.framework

These frameworks are automatically linked by Xcode. No manual configuration required.
```

### CocoaPods Dependencies

**Cordova Declaration:**
```xml
<framework src="GoogleMaps" type="podspec" spec="~> 3.5.0" />
<!-- OR -->
<podspec>
    <pods use-frameworks="true">
        <pod name="Alamofire" spec="~> 5.4" />
        <pod name="SwiftyJSON" spec="~> 5.0" />
    </pods>
</podspec>
```

**Migration Strategy:** ⚠️ **Moderate Complexity**

Standard CocoaPods deps belong in **the plugin's own `<PluginName>.podspec`**
as `s.dependency '...'` entries, the plugin author's responsibility. When
the consumer runs `pod install`, CocoaPods resolves them transitively. The
consumer does not add them to their Podfile.

**Plugin author authors this (inside the Capacitor plugin package):**

```ruby
# capacitor-myplugin/CapacitorMyPlugin.podspec
Pod::Spec.new do |s|
  s.name = 'CapacitorMyPlugin'
  # ...
  s.dependency 'Capacitor'
  s.dependency 'GoogleMaps', '~> 8.3.0'
  s.dependency 'Alamofire', '~> 5.4'
  s.dependency 'SwiftyJSON', '~> 5.0'
end
```

**Consumer-facing `MIGRATION.md` entry (only when version compatibility
notes are needed):**

```markdown
### iOS requirements

This plugin bundles its own CocoaPods dependencies. Your app does not need
to add `pod 'GoogleMaps'` to the Podfile manually. Verify your host app
meets:

- iOS deployment target ≥ 15.0 (Capacitor 8 minimum)
- Xcode 26+ (Capacitor 8 minimum)
- `pod install --repo-update` after running `npx cap sync ios`
```

If pods need a non-default CocoaPods source (e.g., a private pod spec
repo), that **is** a consumer-facing item, record it in
`migration.warnings` and document the `source '<url>'` line for the
consumer's Podfile.

**Potential Issues:**
- ❌ **Blocker**: Deprecated or abandoned pods (no updates in 3+ years)
- ❌ **Blocker**: Pods requiring old Swift versions incompatible with current Xcode
- ⚠️ **Warning**: Version conflicts with other plugins
- ⚠️ **Warning**: Pods with complex installation requirements

### Swift Package Manager (SPM)

Modern Cordova plugins increasingly ship a `Package.swift` alongside the
`<podspec>` block so the same source builds under both CocoaPods and SPM.
The relevant plugin.xml markers to detect this pattern are:

```xml
<platform name="ios" package="swift">
  <podspec>
    <pods use-frameworks="true">
      <pod name="FirebaseAnalytics" spec="10.29.0" nospm="true" />
    </pods>
  </podspec>
</platform>
```

- `<platform package="swift">`, tells Cordova's iOS build to look for a
  sibling `Package.swift` and prefer SPM.
- `nospm="true"` on a `<pod>` element, tells the CocoaPods path to skip
  this pod because the same dependency is being satisfied by `Package.swift`.
- A `Package.swift` at the plugin root with one product, one target per
  Swift source root, and `.product(name: "Cordova", package: "cordova-ios")`
  in target dependencies so the Cordova umbrella header resolves under SPM.
- Swift sources gain explicit `import Foundation` and `#if canImport(Cordova)`
  guards because the umbrella import that CocoaPods provides isn't there
  under SPM.

#### What this means for the Capacitor port

Capacitor supports SPM as a first-class iOS option (and on Capacitor 8
it's the default for new plugins). Plugins typically
ship **both** `Package.swift` and `<PluginName>.podspec` so consumers can
choose. The official Capacitor scaffolder (`npm init @capacitor/plugin`)
generates both.

When migrating a Cordova plugin that already ships SPM support, the
migrator should:

1. Detect `<platform package="swift">` and `nospm="true"` markers.
2. Read the existing `Package.swift` (if present at the Cordova plugin
   root) and lift its `dependencies` array into the YAML's
   `dependencies.ios.spm`.
3. Lift any pods **without** `nospm="true"` into `dependencies.ios.cocoapods`
   (those are CocoaPods-only deps without SPM equivalents).
4. Set `migration.notes` to call out that the original plugin already had
   SPM support, the generator should populate both `Package.swift` and
   `.podspec` symmetrically.

**Plugin author authors this (inside the Capacitor plugin package):**

```swift
// capacitor-myplugin/Package.swift
let package = Package(
    name: "CapacitorMyPlugin",
    platforms: [.iOS(.v15)],
    products: [.library(name: "CapacitorMyPlugin", targets: ["CapacitorMyPlugin"])],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "7.0.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.29.0")
    ],
    targets: [
        .target(
            name: "CapacitorMyPlugin",
            dependencies: [
                .product(name: "Capacitor",  package: "capacitor-swift-pm"),
                .product(name: "Cordova",    package: "capacitor-swift-pm"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk")
            ],
            path: "ios/Sources/CapacitorMyPlugin")
    ]
)
```

(`capacitor-swift-pm` is the SPM-compatible Capacitor distribution; check
the official Capacitor docs for the exact package name and required version
at the time of generation.)

```ruby
# capacitor-myplugin/CapacitorMyPlugin.podspec
Pod::Spec.new do |s|
  s.dependency 'Capacitor'
  s.dependency 'FirebaseAnalytics', '~> 10.29.0'
end
```

#### YAML shape for SPM entries

The generator's input contract is silent on the exact entry shape under
`dependencies.ios.spm`. Use a flat string per entry that captures URL and
version constraint:

```yaml
dependencies:
  ios:
    spm:
      - "https://github.com/firebase/firebase-ios-sdk.git@from:10.29.0"
      - "https://github.com/Alamofire/Alamofire.git@upToNextMajor:5.0.0"
    cocoapods: []                    # only deps without SPM equivalents
```

If the generator-side contract gets a structured SPM schema later
(e.g., `{url, version, products}`), migrate to it then. For now the
string form is what the generator can parse without contract drift.

#### When to flag as a blocker

- ❌ SPM dependency is at a Git tag or branch that no longer resolves.
  Blocker until the URL is updated or an alternative is approved.
- ❌ Plugin uses both `<framework custom="true">` (binary) and `Package.swift`
  with conflicting symbol exports, blocker until vendor clarifies which to
  use.
- ⚠️ Plugin's `Package.swift` declares `platforms: [.iOS(.v17)]` but the
  consumer's app targets iOS 15 (the Capacitor 8 minimum), warning;
  consumer must bump deployment target.

### Manual/Custom Frameworks

**Cordova Declaration:**
```xml
<framework src="libs/CustomSDK.framework" custom="true" />
```

**Migration Strategy:** ⚠️ **Moderate-High Complexity**

Custom frameworks require manual copying and linking.

**Steps:**
1. Identify framework files and their locations
2. Determine if framework is universal (iOS + Simulator) or device-only
3. Check for bitcode/architecture requirements
4. Document manual installation

**Documentation Template:**
```markdown
### iOS Custom Framework Setup

This plugin requires a custom framework that must be manually added:

1. Download `CustomSDK.framework` from [source URL]
2. Copy it to `ios/App/Frameworks/`
3. Open `ios/App/App.xcworkspace` in Xcode
4. Select the App target
5. Go to "Frameworks, Libraries, and Embedded Content"
6. Click "+" and add `CustomSDK.framework`
7. Set "Embed" to "Embed & Sign"

**Important:**
- This framework requires iOS 15.0+ (Capacitor 8 minimum)
- XCFramework format is required for Simulator + Device support
- Ensure the framework supports arm64 architecture
```

**Potential Issues:**
- ❌ **Blocker**: Framework is device-only (no simulator support) - breaks development workflow
- ❌ **Blocker**: Framework is 32-bit only (not supported in modern iOS)
- ❌ **Blocker**: Framework requires bitcode (deprecated in Xcode 14, removed entirely in Xcode 15; `ENABLE_BITCODE` is a no-op in Xcode 16+)
- ⚠️ **Warning**: Framework is not XCFramework format (may cause architecture issues)

### Vendored XCFrameworks Checked Into the Plugin Tree

Some Cordova plugins ship a binary `.xcframework` directly in
`src/ios/frameworks/`, declared like this in `plugin.xml`:

```xml
<framework src="src/ios/frameworks/MyVendorLib.xcframework"
           embed="true" custom="true" />
```

**Migration Strategy:** ✅ **Carry the binary forward**, this is **not** a
blocker on its own. The binary is already publicly available (it ships with
the plugin). The Capacitor plugin keeps the same vendored binary.

**Steps:**

1. Verify the xcframework contains the required slices (arm64 device,
   arm64+x86_64 simulator). Run:
   ```bash
   plutil -p src/ios/frameworks/MyVendorLib.xcframework/Info.plist | head
   ```
2. Record the binary's source path in the migration YAML:
   ```yaml
   migration:
     source_files:
       ios:
         - src/ios/frameworks/MyVendorLib.xcframework
   ```
3. Tell the generator to copy the directory to the new plugin's
   `ios/Sources/` or `ios/Plugin/` location and reference it in the
   `.podspec`:
   ```ruby
   s.vendored_frameworks = 'ios/Sources/MyVendorLib.xcframework'
   ```

**Blocker triggers (when this DOES become a blocker):**

- ❌ Binary is missing simulator slices and the user needs simulator-based
  development.
- ❌ Binary is unsigned and the host project requires signed dependencies.
- ❌ Binary's `Info.plist` declares an `IPHONEOS_DEPLOYMENT_TARGET` higher
  than the host app's minimum target and the user has not consented to bump.

**When NOT a blocker:**

- ✅ Binary is publicly distributed alongside the plugin source.
- ✅ Binary has both device and simulator slices.
- ✅ Binary is properly code-signed by the vendor.

---

## Android Dependencies

### Gradle Dependencies (Maven)

**Cordova Declaration:**
```xml
<framework src="com.google.android.gms:play-services-maps:18.0.0" />
<framework src="com.squareup.okhttp3:okhttp:4.9.0" />
<framework src="androidx.appcompat:appcompat:1.4.0" />
```

**Migration Strategy:** ⚠️ **Moderate Complexity**

Standard Gradle deps belong in **the plugin's own `android/build.gradle`**.
That's the plugin author's responsibility; the consumer does not add them.
Gradle resolves them transitively when the plugin's npm package is linked
via `npx cap sync`.

**Plugin-author steps:**
1. Identify all Gradle dependencies from `plugin.xml`.
2. Check for version compatibility with current Android SDK.
3. Verify AndroidX vs Support Library usage.
4. Add the `implementation '...'` lines to the Capacitor plugin's
   `android/build.gradle` `dependencies { }` block.

**Plugin author authors this (inside the Capacitor plugin package):**

```gradle
// capacitor-myplugin/android/build.gradle
dependencies {
    implementation project(':capacitor-android')

    // Migrated from Cordova plugin.xml <framework> entries:
    implementation 'com.google.android.gms:play-services-maps:18.2.0'
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'
}
```

For AndroidX modules Capacitor itself depends on (`androidx.appcompat`,
`androidx.core`, `androidx.activity`, `androidx.fragment`,
`androidx.webkit`, `androidx.coordinatorlayout`), do **not** redeclare
them with a pinned version in the plugin's gradle. The plugin inherits
whatever `capacitor-android` resolves, which is the version Capacitor's
own `android/capacitor/build.gradle` pins at that release tag. Pinning a
different version in the plugin can fight Capacitor's resolution and
create conflicts in the consumer's app. If the plugin genuinely needs a
feature from a newer AndroidX release than Capacitor ships, surface that
in `migration.warnings` and let the reviewer decide whether to bump.

If you need to confirm the exact pins, read
`android/capacitor/build.gradle` in the `ionic-team/capacitor`
repository at the Capacitor release tag you're targeting. These values
move with each Capacitor release, so look them up at generation time
rather than copying numbers from this doc.

Gradle and Android Gradle Plugin versions are **not** the plugin's
concern. The Capacitor app template that scaffolds the consumer's host
app already ships compatible Gradle wrapper + AGP for the Capacitor
version they installed. Plugins should leave Gradle/AGP alone.

**Consumer-facing `MIGRATION.md` entry (only when version compatibility
notes are needed):**

```markdown
### Android requirements

This plugin bundles its own Gradle dependencies. Your app does not need to
add them manually. Verify your host app meets:

- `compileSdk` 36 (Capacitor 8 minimum)
- `minSdk` 24 (Capacitor 8 minimum)
- AndroidX (Capacitor requirement; Jetifier is not supported)
- Java 21 source/target (Capacitor 8 builds with `JavaVersion.VERSION_21`)

Keep your Capacitor install current and `npx cap sync` after installing
the plugin. The Capacitor CLI handles Gradle and AGP versions for you;
don't pin them manually.
```

If the plugin's own gradle has version conflicts with the host app's
gradle (e.g., two transitive okhttp versions), surface that in
`migration.warnings` so the consumer knows to pin a resolution strategy.

**Potential Issues:**
- ❌ **Blocker**: Dependency uses Support Library (not AndroidX) - incompatible with modern Capacitor
- ❌ **Blocker**: Dependency requires old compile/target SDK versions
- ⚠️ **Warning**: Version conflicts with other plugins or Capacitor core
- ⚠️ **Warning**: Large dependency size (>50MB)

### Custom Repositories

**Cordova Declaration:**
```xml
<framework src="com.example:custom-sdk:1.0.0" />
<preference name="android-build-tool" value="gradle" />
<resource-file src="libs/maven-repo.gradle" target="repositories.gradle" />
```

**Migration Strategy:** ⚠️ **Moderate-High Complexity**

Custom Maven repositories are one of the **consumer-side** items, Gradle
does not propagate `repositories {}` blocks from a plugin module to the
host app, so the consumer must add the URL to their own root
`build.gradle` (or `settings.gradle` for projects using
`dependencyResolutionManagement`). The plugin author still puts the
`implementation` line in the plugin's own `android/build.gradle`.

**Plugin author authors this (inside the Capacitor plugin package):**

```gradle
// capacitor-myplugin/android/build.gradle
dependencies {
    implementation 'com.example:custom-sdk:1.0.0'
}
```

**Consumer-facing `MIGRATION.md` entry:**

```markdown
### Android custom Maven repository

This plugin pulls one of its dependencies from a private Maven repo.
Add the repository URL to **your host app's** root `android/build.gradle`:

\`\`\`gradle
allprojects {
    repositories {
        // ... existing repositories ...
        maven {
            url "https://maven.example.com/repository"
            credentials {
                username = project.findProperty("EXAMPLE_MAVEN_USERNAME") ?: ""
                password = project.findProperty("EXAMPLE_MAVEN_PASSWORD") ?: ""
            }
        }
    }
}
\`\`\`

(For projects using `dependencyResolutionManagement` in `settings.gradle`,
which is the modern Gradle convention used by Capacitor 8, add the entry
under `dependencyResolutionManagement.repositories` instead of in the
root `build.gradle`.)

If the repo requires credentials, add them to your `gradle.properties`:

\`\`\`properties
EXAMPLE_MAVEN_USERNAME=your-username
EXAMPLE_MAVEN_PASSWORD=your-password
\`\`\`

You do **not** need to add the `implementation 'com.example:custom-sdk:1.0.0'`
line to your app, the plugin's own gradle already declares it and Gradle
will resolve it transitively once the repo is reachable.
```

**Potential Issues:**
- ❌ **Blocker**: Private repository requires authentication not available to end users
- ❌ **Blocker**: Repository is no longer accessible/maintained
- ⚠️ **Warning**: Repository requires VPN or specific network access

### Local AAR/JAR Files

**Cordova Declaration:**
```xml
<framework src="libs/custom-library.aar" custom="true" />
```

**Migration Strategy:** ⚠️ **High Complexity**

Local library files come in two flavors with very different ownership:

| Case | Ships with the plugin? | Who handles it |
| --- | --- | --- |
| Vendor distributes the AAR publicly (or it is vendored in the original Cordova plugin's `src/android/libs/`) | Yes, copy into the Capacitor plugin's own `android/libs/` and the plugin's `build.gradle` references it. Bundled inside the npm package. | Plugin author. Consumer takes no action. |
| Vendor requires the consumer to download a signed/licensed AAR themselves (cannot ship via npm) | No, the consumer must download and place the AAR in their host app. | Consumer. Plugin author documents the URL and target path. |

**Plugin-author authors this (vendored case, inside the Capacitor plugin
package):**

```gradle
// capacitor-myplugin/android/build.gradle
dependencies {
    implementation fileTree(dir: 'libs', include: ['*.aar'])
}
```

with the `.aar` copied into `capacitor-myplugin/android/libs/`, record
the source path under `migration.source_files.android` so the generator
picks it up.

**Consumer-facing `MIGRATION.md` entry (only when the vendor forbids
redistribution):**

```markdown
### Android local library (license-required)

This plugin depends on `custom-library.aar`, which the vendor does not
permit us to redistribute.

1. Download `custom-library.aar` from [vendor URL].
2. Place it at `android/app/libs/custom-library.aar` in your host app.
3. Add to your **app's** `android/app/build.gradle`:
   \`\`\`gradle
   dependencies {
       implementation files('libs/custom-library.aar')
   }
   \`\`\`
4. Run `npx cap sync android`.

This is the only Android binary you have to copy by hand, all other plugin
dependencies are bundled inside the npm package.
```

The license-required path is the **only** time a consumer should add an
`implementation files(...)` line. Treat it as a flagged blocker in the
migration plan until the user confirms they can satisfy the license terms.

**Potential Issues:**
- ❌ **Blocker**: AAR file is not publicly available
- ❌ **Blocker**: AAR requires specific ProGuard rules not documented
- ❌ **Blocker**: AAR is compiled for old Android SDK version
- ⚠️ **Warning**: AAR has undocumented transitive dependencies

---

## Dependency Migration Strategies

### Strategy 1: Direct Migration ✅

**When Applicable:**
- Public, well-maintained dependencies
- Compatible with current iOS/Android versions
- No architectural changes needed

**Process:**
1. Identify dependency name and version
2. Check latest compatible version
3. Document in README with installation instructions
4. Test dependency integration

**Example:**
```
Cordova: <framework src="com.google.android.gms:play-services-maps:18.0.0" />
Capacitor: implementation 'com.google.android.gms:play-services-maps:18.1.0'
Status: ✅ Direct migration - public, well-maintained
```

### Strategy 2: Version Update ⚠️

**When Applicable:**
- Dependency has newer versions available
- Old version incompatible with current SDK
- Security or compatibility improvements

**Process:**
1. Identify current version in plugin.xml
2. Research breaking changes in newer versions
3. Update native code if API changes
4. Document version requirement and changes

**Example:**
```
Cordova: <framework src="Alamofire" spec="~> 4.0" />
Issue: Alamofire 4.x uses Swift 4, incompatible with modern Xcode
Solution: Upgrade to Alamofire 5.x (requires code changes)
Status: ⚠️ Moderate - requires API updates
```

### Strategy 3: Alternative Dependency 🔄

**When Applicable:**
- Original dependency is deprecated/abandoned
- Better alternative exists
- Original requires extensive workarounds

**Process:**
1. Identify replacement dependency
2. Map old API to new API
3. Update native implementation code
4. Document replacement and reasons

**Example:**
```
Cordova: <framework src="deprecated-http-library:1.0" />
Issue: Library abandoned, no AndroidX support
Solution: Replace with OkHttp 4.x (modern, maintained)
Status: 🔄 Replacement required - significant code changes
```

### Strategy 4: Migration Blocker ❌

**When Applicable:**
- Dependency is proprietary/unavailable
- Requires incompatible SDK versions
- No viable alternative exists
- Licensing issues

**Process:**
1. Clearly document why dependency blocks migration
2. Propose workarounds (if any)
3. Estimate effort to remove dependency
4. Flag for user decision

**Example:**
```
Cordova: <framework src="proprietary-sdk.aar" custom="true" />
Issue: SDK no longer available, requires Android SDK 19 (EOL)
Status: ❌ MIGRATION BLOCKER
Options:
  1. Contact vendor for updated SDK
  2. Remove feature depending on this SDK
  3. Re-implement functionality natively
```

---

## Migration Blockers

### iOS Dependency Blockers

**Deprecated/Abandoned CocoaPods:**
- Pod not updated in 3+ years
- No support for current Swift version
- Requires deprecated bitcode support

**Example:**
```markdown
❌ **Blocker**: AFNetworking 2.x
- Last updated 2016, requires iOS 7+
- No Swift 5+ support
- Solution: Migrate to Alamofire or native URLSession
```

**Incompatible Architectures:**
- Framework doesn't support arm64 (required for iOS 11+)
- Framework is 32-bit only (not supported since iOS 11)
- No simulator support (breaks development workflow)

**Example:**
```markdown
❌ **Blocker**: CustomSDK.framework
- Device-only binary (no x86_64/arm64 simulator slices)
- Breaks local development and testing
- Solution: Request XCFramework from vendor or rebuild with simulator support
```

**Private/Proprietary Frameworks:**
- Framework not publicly available
- Requires license key or special access
- Vendor no longer provides support

### Android Dependency Blockers

**Support Library (Non-AndroidX):**
- Uses `android.support.*` packages
- Incompatible with AndroidX (Capacitor requirement)
- No migration path available

**Example:**
```markdown
❌ **Blocker**: com.example:legacy-library:1.0
- Uses Support Library (android.support.v4)
- Capacitor requires AndroidX
- Solution: Contact vendor for AndroidX version or use Jetifier (temporary workaround)
```

**Incompatible SDK Versions:**
- Requires `compileSdk` < 28 (pre-AndroidX cutoff)
- Requires old Java version (Capacitor 8 builds with Java 21; `sourceCompatibility` / `targetCompatibility` are both `VERSION_21`)
- Incompatible with current AGP / Gradle distribution

**Example:**
```markdown
❌ **Blocker**: com.old:sdk:1.0
- Requires compileSdk 25 (Android 7.1)
- Capacitor 8 requires compileSdk 36 (Android 16) and minSdk 24 (Android 7.0)
- Solution: Update dependency or remove feature
```

**Unavailable Dependencies:**
- Private Maven repository no longer accessible
- AAR file not available for download
- Requires authentication credentials users don't have

---

## Analysis Output Template

Include this section in your migration analysis when dependencies are found:

```markdown
## 📦 Third-Party Dependencies Analysis

### iOS Dependencies

#### System Frameworks
- ✅ **CoreLocation.framework**
  - Migration: Automatic linking by Xcode
  - Complexity: Low
  - Action: None required

- ✅ **MapKit.framework**
  - Migration: Automatic linking by Xcode
  - Complexity: Low
  - Action: None required

#### CocoaPods Dependencies
- ⚠️ **GoogleMaps (~> 3.5.0)**
  - Current Version: 3.5.0
  - Latest Compatible: 8.3.0
  - Migration Strategy: Direct migration with version update
  - Complexity: Moderate
  - Action Required: Add to Podfile
  - Breaking Changes: API changes in GoogleMaps 4.x+ (method renaming)

  \`\`\`ruby
  # Add to ios/App/Podfile:
  pod 'GoogleMaps', '~> 8.3.0'
  \`\`\`

- ❌ **AFNetworking (~> 2.0)** - **MIGRATION BLOCKER**
  - Issue: Abandoned library, last updated 2016
  - No Swift 5 support
  - Recommendation: Replace with Alamofire 5.x or native URLSession
  - Impact: Requires rewriting all networking code
  - Effort: High (2-3 days)

#### Custom Frameworks
- ⚠️ **CustomSDK.framework**
  - Type: Manual binary framework
  - Migration Strategy: Manual installation required
  - Complexity: Moderate-High
  - Issues: Device-only binary (no simulator support)
  - Recommendation: Request XCFramework from vendor
  - Workaround: Use #if targetEnvironment(simulator) guards

---

### Android Dependencies

#### Gradle Dependencies
- ✅ **com.google.android.gms:play-services-maps:18.0.0**
  - Latest Compatible: 18.2.0
  - Migration Strategy: Direct migration with version update
  - Complexity: Low
  - Action Required: Add to build.gradle

  \`\`\`gradle
  // Add to android/app/build.gradle:
  implementation 'com.google.android.gms:play-services-maps:18.2.0'
  \`\`\`

- ⚠️ **com.squareup.okhttp3:okhttp:4.9.0**
  - Latest Compatible: 4.12.0
  - Migration Strategy: Direct migration
  - Complexity: Low
  - Note: Ensure Kotlin compatibility (OkHttp 4.x requires Kotlin)

#### Local Libraries
- ❌ **libs/proprietary-sdk.aar** - **MIGRATION BLOCKER**
  - Issue: Binary not publicly available
  - Requires vendor account access
  - Uses Support Library (non-AndroidX)
  - Recommendation: Contact vendor for:
    1. AndroidX-compatible version
    2. Public Maven distribution
    3. Or remove feature depending on this SDK
  - Impact: Critical feature unavailable without resolution

---

## 📋 Dependency Migration Summary

**Total Dependencies:** [Number]
- ✅ **Direct Migration:** [Number] - Can migrate as-is or with version update
- ⚠️ **Requires Workarounds:** [Number] - Manual setup, version updates, or code changes needed
- 🔄 **Requires Replacement:** [Number] - Need alternative libraries
- ❌ **Migration Blockers:** [Number] - Cannot migrate without resolution

**Overall Dependency Assessment:**
[Straightforward / Moderate Complexity / High Complexity / Blocked]

**Critical Actions Required:**
1. [Action 1 - e.g., Contact vendor for updated SDK]
2. [Action 2 - e.g., Decide whether to remove feature X]
3. [Action 3 - e.g., Rewrite networking layer to replace AFNetworking]

**Recommended Next Steps:**
1. Resolve migration blockers before proceeding
2. Test all dependencies in a test Capacitor project
3. Document all manual setup steps in plugin README
4. Create dependency compatibility matrix for users
```

---

## Dependency Analysis Checklist

When analyzing dependencies, verify:

**iOS:**
- [ ] All `<framework>` tags identified in plugin.xml
- [ ] System frameworks identified (automatic linking)
- [ ] CocoaPods dependencies identified and versions checked
- [ ] Custom frameworks/libraries identified
- [ ] Swift Package Manager dependencies identified (if any)
- [ ] All pods checked for current Swift/Xcode compatibility
- [ ] Version conflicts with Capacitor core checked
- [ ] Deprecated or abandoned pods flagged
- [ ] Migration path documented for each dependency

**Android:**
- [ ] All `<framework>` tags identified in plugin.xml
- [ ] Gradle dependencies identified and versions checked
- [ ] Local AAR/JAR files identified
- [ ] Custom Maven repositories identified
- [ ] AndroidX vs Support Library usage checked
- [ ] Minimum SDK version compatibility verified
- [ ] Version conflicts with Capacitor core checked
- [ ] Deprecated or unavailable dependencies flagged
- [ ] Migration path documented for each dependency

**General:**
- [ ] All dependencies categorized by migration strategy
- [ ] Migration blockers clearly flagged
- [ ] Alternative dependencies researched for blockers
- [ ] Manual installation steps documented
- [ ] Dependency size and impact assessed
- [ ] Licensing issues identified (if any)
