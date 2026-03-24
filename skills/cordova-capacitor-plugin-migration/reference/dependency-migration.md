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

Third-party dependencies are a critical aspect of plugin migration. Cordova automatically injects dependencies via plugin.xml, while Capacitor requires manual dependency management in native projects.

**Key Differences:**

| Aspect | Cordova | Capacitor |
|--------|---------|-----------|
| **Declaration** | plugin.xml `<framework>` tags | Native dependency files (Podfile, build.gradle) |
| **Installation** | Automatic during plugin install | Manual by app developer |
| **Version Management** | Fixed in plugin.xml | Flexible in native projects |
| **Dependency Type** | iOS: CocoaPods, Frameworks<br>Android: Gradle, JARs | iOS: CocoaPods, SPM<br>Android: Gradle |

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
```

**Migration Strategy:** ✅ **Low Complexity**

System frameworks are built into iOS and don't require CocoaPods. In Capacitor:

**Option 1: Automatic Linking (Preferred)**
Most system frameworks are automatically linked by Xcode. No action needed.

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

CocoaPods dependencies must be manually added to the app's Podfile.

**Steps:**
1. Identify all CocoaPods dependencies
2. Check for version compatibility with current iOS/Xcode
3. Document manual installation in README

**Documentation Template:**
```markdown
### iOS CocoaPods Setup

Add the following to your `ios/App/Podfile`:

\`\`\`ruby
target 'App' do
  # ... existing pods ...

  # MyPlugin dependencies
  pod 'GoogleMaps', '~> 3.5.0'
  pod 'Alamofire', '~> 5.4'
  pod 'SwiftyJSON', '~> 5.0'
end
\`\`\`

Then run:
\`\`\`bash
cd ios/App
pod install
\`\`\`

**Version Compatibility:**
- GoogleMaps 3.5.0+ requires iOS 12.0+
- Alamofire 5.4+ requires iOS 10.0+
- SwiftyJSON 5.0+ requires iOS 8.0+
```

**Potential Issues:**
- ❌ **Blocker**: Deprecated or abandoned pods (no updates in 3+ years)
- ❌ **Blocker**: Pods requiring old Swift versions incompatible with current Xcode
- ⚠️ **Warning**: Version conflicts with other plugins
- ⚠️ **Warning**: Pods with complex installation requirements

### Swift Package Manager (SPM)

**Cordova Declaration:**
Rare in Cordova, but modern plugins may reference SPM packages.

**Migration Strategy:** ✅ **Low-Moderate Complexity**

SPM is well-supported in Capacitor. Dependencies can be added via Xcode or Package.swift.

**Documentation Template:**
```markdown
### iOS Swift Package Manager Setup

Add the following Swift packages to your Xcode project:

1. Open `ios/App/App.xcworkspace` in Xcode
2. Go to File → Add Packages...
3. Add the following packages:
   - **Alamofire**: https://github.com/Alamofire/Alamofire (Up to Next Major: 5.0.0)
   - **SwiftyJSON**: https://github.com/SwiftyJSON/SwiftyJSON (Up to Next Major: 5.0.0)

Alternatively, add to `ios/App/App/Package.swift` if using SPM directly.
```

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
- This framework requires iOS 13.0+
- XCFramework format is required for Simulator + Device support
- Ensure the framework supports arm64 architecture
```

**Potential Issues:**
- ❌ **Blocker**: Framework is device-only (no simulator support) - breaks development workflow
- ❌ **Blocker**: Framework is 32-bit only (not supported in modern iOS)
- ❌ **Blocker**: Framework requires bitcode (deprecated in Xcode 14+)
- ⚠️ **Warning**: Framework is not XCFramework format (may cause architecture issues)

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

Gradle dependencies must be manually added to the app's build.gradle.

**Steps:**
1. Identify all Gradle dependencies
2. Check for version compatibility with current Android SDK
3. Verify AndroidX vs Support Library usage
4. Check for transitive dependency conflicts
5. Document manual installation in README

**Documentation Template:**
```markdown
### Android Gradle Setup

Add the following to your `android/app/build.gradle`:

\`\`\`gradle
dependencies {
    // ... existing dependencies ...

    // MyPlugin dependencies
    implementation 'com.google.android.gms:play-services-maps:18.1.0'
    implementation 'com.squareup.okhttp3:okhttp:4.10.0'
    implementation 'androidx.appcompat:appcompat:1.4.2'
}
\`\`\`

**Minimum Requirements:**
- Android SDK 21+ (Android 5.0)
- Google Play Services 18.1.0+
- AndroidX (not Support Library)

**Syncing:**
After adding dependencies, sync your project:
\`\`\`bash
cd android
./gradlew build
\`\`\`
```

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

Custom Maven repositories must be added to the app's repositories configuration.

**Documentation Template:**
```markdown
### Android Custom Repository Setup

Add the following to your `android/build.gradle`:

\`\`\`gradle
allprojects {
    repositories {
        // ... existing repositories ...

        // MyPlugin custom repository
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

Add credentials to `gradle.properties`:
\`\`\`properties
EXAMPLE_MAVEN_USERNAME=your-username
EXAMPLE_MAVEN_PASSWORD=your-password
\`\`\`

Then add the dependency to `android/app/build.gradle`:
\`\`\`gradle
implementation 'com.example:custom-sdk:1.0.0'
\`\`\`
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

Local library files must be manually copied and configured.

**Documentation Template:**
```markdown
### Android Local Library Setup

This plugin requires a custom Android library:

1. Download `custom-library.aar` from [source URL]
2. Create directory `android/app/libs/` if it doesn't exist
3. Copy `custom-library.aar` to `android/app/libs/`
4. Add to `android/app/build.gradle`:

\`\`\`gradle
dependencies {
    // ... existing dependencies ...

    implementation files('libs/custom-library.aar')
    // OR for all AAR files in libs:
    implementation fileTree(dir: 'libs', include: ['*.aar'])
}
\`\`\`

5. Sync Gradle:
\`\`\`bash
cd android
./gradlew build
\`\`\`

**Requirements:**
- Library requires Android SDK 23+ (Android 6.0)
- Compiled with Java 8+
```

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
- Requires compileSdkVersion < 28
- Requires old Java version (< 8)
- Incompatible with Gradle 7+

**Example:**
```markdown
❌ **Blocker**: com.old:sdk:1.0
- Requires compileSdkVersion 25 (Android 7.1)
- Capacitor requires SDK 33+ (Android 13)
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
