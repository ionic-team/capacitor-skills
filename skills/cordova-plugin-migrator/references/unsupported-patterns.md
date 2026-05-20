# Unsupported Cordova Patterns in Capacitor

This reference provides detailed explanations of Cordova patterns that cannot be directly converted to Capacitor and their workarounds.

## Contents

- [Config File Modifications](#config-file-modifications)
- [Installation Hooks](#installation-hooks)
- [Framework and Dependency Injection](#framework-and-dependency-injection)
- [JavaScript Module Auto-Execution](#javascript-module-auto-execution)
- [Preferences and Variables](#preferences-and-variables)
- [Permissions](#permissions)
- [Summary Table](#summary-table)

---

## Config File Modifications

### Cordova Pattern

```xml
<config-file target="AndroidManifest.xml" parent="/manifest/application">
    <activity android:name="com.example.CustomActivity" />
</config-file>

<config-file target="*-Info.plist" parent="NSCameraUsageDescription">
    <string>App needs camera access</string>
</config-file>
```

### Why It Fails

Capacitor does **not** modify native project files automatically. In Capacitor:
- Native projects are **source code**, not build artifacts
- Developers maintain full control over native projects
- Modifications must be done manually or via custom scripts

### Migration Strategy

1. **Document all required native configuration changes**
2. **Provide manual configuration steps in plugin README**
3. **Consider creating a setup script users run after installation**
4. **iOS**: Users must edit `Info.plist` manually
5. **Android**: Users must edit `AndroidManifest.xml` manually

### Example Documentation

```markdown
## iOS Setup

Add the following to your `Info.plist`:

\`\`\`xml
<key>NSCameraUsageDescription</key>
<string>App needs camera access</string>
\`\`\`

## Android Setup

Add the following to your `AndroidManifest.xml` inside the `<application>` tag:

\`\`\`xml
<activity android:name="com.example.CustomActivity" />
\`\`\`
```

### When to Flag as Blocker

- ❌ **Blocker**: Extensive modifications across multiple files
- ❌ **Blocker**: Complex conditional modifications
- ⚠️ **Warning**: Simple, well-documented manual steps

### Entitlement Plists (iOS Capabilities)

A specific case worth calling out: `<config-file>` targets that end in
`-Debug.plist`, `-Release.plist`, or `-Entitlements.plist` mutate the **app
entitlement plist**, not Info.plist. These map to Xcode "Signing &
Capabilities" entries, not to consumer-facing privacy strings.

**Cordova Pattern:**

```xml
<!-- Apple Pay capability -->
<config-file target="*-Debug.plist" parent="com.apple.developer.in-app-payments">
  <array>
    <string>merchant.com.example.app</string>
  </array>
</config-file>
<config-file target="*-Release.plist" parent="com.apple.developer.in-app-payments">
  <array>
    <string>merchant.com.example.app</string>
  </array>
</config-file>
```

**Capacitor Migration:**

- Document the **exact Xcode capability** the user must enable (Apple Pay,
  Push Notifications, App Groups, etc.) in `MIGRATION.md`.
- Document the **entitlement value** (merchant ID, app group identifier).
- Record under `migration.warnings`. Not a blocker, but easy to miss
  because the consumer must toggle a capability in Xcode by hand.

**Example documentation block:**

```markdown
## iOS Capabilities

This plugin requires the **Apple Pay** capability.

1. Open `ios/App/App.xcworkspace` in Xcode.
2. Select the App target.
3. Go to **Signing & Capabilities → + Capability → Apple Pay**.
4. Add your Apple Pay merchant ID under "Merchant IDs":
   `merchant.com.example.app`.
5. Repeat for both Debug and Release configurations if they differ.
```

Common capability targets:

| Cordova parent | Xcode capability |
| --- | --- |
| `com.apple.developer.in-app-payments` | Apple Pay |
| `aps-environment` | Push Notifications |
| `com.apple.developer.associated-domains` | Associated Domains |
| `com.apple.security.application-groups` | App Groups |
| `com.apple.developer.healthkit` | HealthKit |
| `com.apple.developer.networking.wifi-info` | Access Wi-Fi Information |

---

## Installation Hooks

### Cordova Pattern

```xml
<hook type="before_plugin_install" src="scripts/beforeInstall.js" />
<hook type="after_plugin_install" src="scripts/afterInstall.js" />
<hook type="before_prepare" src="scripts/beforePrepare.js" />
<hook type="after_prepare" src="scripts/afterPrepare.js" />
<hook type="before_build" src="scripts/beforeBuild.js" />
<hook type="after_build" src="scripts/afterBuild.js" />
```

### Why It Fails

Cordova's hook system is deeply integrated with the Cordova CLI lifecycle. Capacitor has:
- **No equivalent lifecycle** for some hooks
- **Different sync model** (no "prepare" concept)
- **No install-time hooks** (npm handles installation)

### Migration Strategy

Use the **three-tiered approach** (see [hooks-migration.md](hooks-migration.md) for complete details):

**Tier 1: Capacitor Hooks** (for sync/copy lifecycle)
```json
{
  "hooks": {
    "capacitor:sync:after": "node scripts/script.js"
  }
}
```

**Tier 2: npm Scripts** (for install/uninstall lifecycle)
```json
{
  "scripts": {
    "postinstall": "node scripts/setup.js",
    "preuninstall": "node scripts/cleanup.js"
  }
}
```

**Tier 3: Migration Blocker** (interactive or Cordova-specific)
- Document workarounds
- Propose architectural changes
- Flag as potential blocker

### When to Flag as Blocker

- ❌ **Blocker**: Interactive hooks requiring user input
- ❌ **Blocker**: Hooks modifying plugin.xml/config.xml
- ❌ **Blocker**: Critical hooks with no Capacitor equivalent
- ⚠️ **Warning**: Hooks convertible to Tier 1 or Tier 2

---

## Framework and Dependency Injection

### Cordova Pattern

```xml
<framework src="CoreLocation.framework" />
<framework src="com.google.android.gms:play-services-location:18.0.0" />
<podspec>
    <config>
        <source url="https://github.com/CocoaPods/Specs.git"/>
    </config>
    <pods use-frameworks="true">
        <pod name="GoogleMaps" spec="~> 3.5.0" />
    </pods>
</podspec>
```

### Why It Partially Fails

Capacitor **does not automatically inject** frameworks or dependencies into native projects.

**Status:** ⚠️ Partially supported
- iOS frameworks: Must be added to native Xcode project or via Podfile
- Android dependencies: Must be added to build.gradle manually
- CocoaPods: Users must manage Podfile directly

### Migration Strategy

**Document in README:**

```markdown
## iOS Setup

Add to `ios/App/Podfile`:
\`\`\`ruby
pod 'GoogleMaps', '~> 3.5.0'
\`\`\`

Then run:
\`\`\`bash
cd ios/App
pod install
\`\`\`

## Android Setup

Add to `android/app/build.gradle`:
\`\`\`gradle
dependencies {
    implementation 'com.google.android.gms:play-services-location:21.0.1'
}
\`\`\`
```

### When to Flag as Blocker

- ❌ **Blocker**: Extensive framework dependencies (>5)
- ❌ **Blocker**: Complex version compatibility requirements
- ⚠️ **Warning**: Standard frameworks with simple setup

---

## JavaScript Module Auto-Execution

### Cordova Pattern

```xml
<js-module src="www/init.js" name="Init">
    <runs />
</js-module>
```

This auto-executes code when the plugin loads (typically for initialization).

### Why It Fails

Capacitor does not support auto-execution of plugin code:
- Plugins are imported explicitly
- No global initialization mechanism
- Code runs only when explicitly called

### Migration Strategy

**Option 1: Explicit Initialization**
```typescript
// Plugin exports init method
export interface MyPluginPlugin {
  initialize(): Promise<void>;
}

// App calls it during startup
import { MyPlugin } from 'my-plugin';

async function initApp() {
  await MyPlugin.initialize();
  // ... rest of app initialization
}
```

**Option 2: Plugin Constructor**
```typescript
// Web implementation auto-initializes
export class MyPluginWeb extends WebPlugin implements MyPluginPlugin {
  constructor() {
    super();
    this.initialize(); // Auto-init on web
  }

  private initialize(): void {
    // Initialization code
  }
}
```

**Option 3: Document in README**
```markdown
## Initialization

Call the initialization method during app startup:

\`\`\`typescript
import { MyPlugin } from 'my-plugin';

await MyPlugin.initialize();
\`\`\`
```

### When to Flag as Blocker

- ⚠️ **Warning**: Most init code can be moved to explicit methods
- ❌ **Blocker**: Critical auto-initialization with complex timing requirements

---

## Preferences and Variables

### Cordova Pattern

```xml
<preference name="API_KEY" default="abc123" />
<config-file target="config.xml" parent="/*">
    <preference name="API_KEY" value="$API_KEY" />
</config-file>
```

Install-time variable substitution:
```bash
cordova plugin add my-plugin --variable API_KEY=xyz789
```

### Why It Fails

Capacitor does not have:
- `config.xml` file
- Install-time variable substitution
- Global preferences system

### Migration Strategy

**Option 1: Capacitor Configuration**
```json
// capacitor.config.json
{
  "plugins": {
    "MyPlugin": {
      "apiKey": "xyz789"
    }
  }
}
```

**Option 2: Environment Variables**
```bash
# .env file
MY_PLUGIN_API_KEY=xyz789
```

```typescript
// Plugin reads from env
const apiKey = process.env.MY_PLUGIN_API_KEY;
```

**Option 3: Runtime Configuration**
```typescript
// Pass config through plugin API
await MyPlugin.configure({
  apiKey: 'xyz789'
});
```

**Option 4: Native Platform Configuration**
```swift
// iOS: Read from Info.plist
let apiKey = Bundle.main.object(forInfoDictionaryKey: "APIKey") as? String
```

```kotlin
// Android: Read from BuildConfig or strings.xml
val apiKey = BuildConfig.API_KEY
```

### When to Flag as Blocker

- ⚠️ **Warning**: Simple configuration values
- ❌ **Blocker**: Complex configuration with many interdependent values

---

## Permissions

### Cordova Pattern

```xml
<config-file target="AndroidManifest.xml" parent="/*">
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
</config-file>

<config-file target="*-Info.plist" parent="NSCameraUsageDescription">
    <string>App needs camera access</string>
</config-file>
```

### Status

**⚠️ Must be documented** - Capacitor does not automatically add permissions

### Migration Strategy

**Document required permissions in README:**

```markdown
## Permissions

### iOS

Add to `ios/App/App/Info.plist`:

\`\`\`xml
<key>NSCameraUsageDescription</key>
<string>App needs camera access</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>App needs photo library access</string>
\`\`\`

### Android

Add to `android/app/src/main/AndroidManifest.xml`:

\`\`\`xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
\`\`\`
```

**Plugin Code - Declare Permissions:**

```kotlin
// Android
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
        // ... implementation
    }
}
```

### When to Flag as Blocker

- ✅ **Not a blocker**: Permissions are well-documented
- ⚠️ **Warning**: Many permissions required (list them clearly)

---

## Summary Table

| Cordova Feature | Capacitor Status | Workaround | Blocker Risk |
|----------------|------------------|------------|--------------|
| `<config-file>` modifications | ❌ Not supported | Manual native configuration required | ⚠️ Medium |
| `<edit-config>` | ❌ Not supported | Manual native configuration required | ⚠️ Medium |
| Hooks (`<hook>`) | ❌ Not supported | Use npm scripts, Capacitor hooks, or manual steps | ⚠️ High (if Tier 3) |
| `<js-module runs="true">` | ❌ Not supported | Move to plugin initialization code | ✅ Low |
| `clobbers` target | ⚠️ Different pattern | Use Capacitor's `registerPlugin()` | ✅ Low |
| `merges` target | ⚠️ Different pattern | Use Capacitor's `registerPlugin()` | ✅ Low |
| `<dependency>` on other plugins | ⚠️ Different | Use npm dependencies + manual checks | ⚠️ Medium |
| `<preference>` tags | ⚠️ Different | Use Capacitor config or manual iOS/Android configs | ✅ Low |
| `<resource-file>` | ⚠️ Different | Manual native project resource management | ⚠️ Medium |
| `<framework>` injection | ⚠️ Partially supported | Manual Podfile/gradle configuration | ✅ Low |
| Permissions | ⚠️ Must document | Document in README, use runtime permission APIs | ✅ Low |

### Blocker Risk Assessment

- ✅ **Low**: Easy to work around with documentation
- ⚠️ **Medium**: Requires manual setup but straightforward
- ❌ **High**: May require architectural changes or extensive manual work

### General Migration Guidelines

1. **Start by identifying all unsupported patterns** in plugin.xml
2. **Assess each pattern** using the guidelines above
3. **Document workarounds** clearly in the migration analysis
4. **Flag high-risk items** as potential migration blockers
5. **Propose solutions** for each blocker before proceeding
