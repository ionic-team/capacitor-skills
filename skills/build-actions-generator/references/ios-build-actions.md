<!-- Source: https://github.com/OutSystems/docs-odc/blob/main/src/eap/building-apps/mobile/build-actions-iOS.md -->
<!-- Raw (for sync): https://raw.githubusercontent.com/OutSystems/docs-odc/main/src/eap/building-apps/mobile/build-actions-iOS.md -->
<!-- Last verified: 2026-05-18 -->

# iOS Build Actions Reference

All iOS build action types supported in the ODC build actions JSON schema.
All actions go under `platforms.ios` in your `buildAction.json`. The full
wrapper structure is always required:

```json
{
  "platforms": {
    "ios": {
      ...actions here...
    }
  }
}
```

Examples in this file show only the `"ios": { ... }` portion for brevity.

All actions except `displayName` and `productName` support an optional
`condition` field for conditional execution — see the Variables & Conditions
section in SKILL.md.

---

## Targets and builds

iOS build actions support optional scoping by Xcode target and build
configuration. When omitted, actions apply to the default target and the
default build.

**Mutual exclusivity:** At any given nesting level, `targets`, `builds`, and
direct actions are **mutually exclusive**. If `targets` is present at a level,
all other keys at that level — including `builds` and any direct actions — are
silently dropped and never processed.

| Placement | Target | Build |
|-----------|--------|-------|
| Root `ios` level | default | default |
| Root `builds` > `"Debug"` | default | `"Debug"` |
| `targets` > `"App"` | `"App"` | default |
| `targets` > `"App"` > `builds` > `"Release"` | `"App"` | `"Release"` |

```json
"ios": {
  "productName": "Applies to default target and build"
}
```

```json
"ios": {
  "targets": {
    "App": {
      "builds": {
        "Debug":   { "displayName": "Debug App" },
        "Release": { "displayName": "Prod App" }
      }
    }
  }
}
```

Because `targets`, `builds`, and direct actions are mutually exclusive at each
level, the two blocks above must be expressed as separate build action entries.
Placing `productName` alongside `targets` in the same object would silently
discard `productName`.

---

## displayName

Sets the app display name shown on the device home screen.

**Type:** `string` | **Conditional:** No

```json
"ios": {
  "displayName": "My App"
}
```

---

## productName

Sets the product name shown in the App Store and on the device.

**Type:** `string` | **Conditional:** No

```json
"ios": {
  "productName": "My App"
}
```

---

## buildSettings

Sets Xcode build settings as key-value pairs.

**Type:** `Record<string, string>` | **Conditional:** Yes

```json
"ios": {
  "buildSettings": {
    "ENABLE_BITCODE": false,
    "SWIFT_VERSION": "5.0"
  }
}
```

---

## buildPhases

Adds or replaces custom shell script build phases in the Xcode project. By
default scripts are appended. Set `replace: true` to use `comment` as a unique
identifier and overwrite an existing build phase.

| Field | Required | Description |
|-------|----------|-------------|
| `comment` | yes | Label for the build phase; used as identifier when `replace: true` |
| `shellPath` | yes | Path to the shell (e.g. `"/bin/sh"`) |
| `shellScript` | yes | Shell script content |
| `inputPaths` | no | Array of input file paths |
| `outputPaths` | no | Array of output file paths |
| `replace` | no | If `true`, finds and replaces the existing phase with matching `comment` |

**Conditional:** Yes

```json
"ios": {
  "buildPhases": [
    {
      "replace": true,
      "comment": "Crashlytics",
      "shellPath": "/bin/sh",
      "shellScript": "\"${PODS_ROOT}/FirebaseCrashlytics/run\"",
      "inputPaths": [
        "\"$(BUILT_PRODUCTS_DIR)/$(INFOPLIST_PATH)\""
      ]
    }
  ]
}
```

---

## plist

Updates `Info.plist` (or a specified plist file) for the target and build. By
default values are merged; set `replace: true` to overwrite the entire target
object.

| Field | Required | Description |
|-------|----------|-------------|
| `entries` | yes | Array of key-value objects to add or update |
| `replace` | no | `true` overwrites existing keys; `false` (default) merges |
| `file` | no | Specific plist file to update; defaults to `Info.plist` |

**When to use `replace: true` vs `replace: false`:**
- Use `replace: true` for plugin-specific configuration keys (SDK identifiers, feature flags, App IDs) where the plugin's value must take precedence over anything the app may have set. This ensures the key is always written with the correct value on every build.
- Use `replace: false` for keys where the app's existing value should be preserved if present — typically usage description strings (`NSCameraUsageDescription`, etc.) where the app may have its own copy already set.

**Conditional:** Yes

```json
"ios": {
  "plist": [
    {
      "replace": true,
      "file": "GoogleService-Info.plist",
      "entries": [{ "Key": "Value" }]
    },
    {
      "replace": false,
      "entries": [
        {
          "CFBundleURLTypes": [
            { "CFBundleURLSchemes": ["myapp"] }
          ]
        },
        { "NSCameraUsageDescription": "Required for scanning." },
        { "NSFaceIDUsageDescription": "Used for authentication." }
      ]
    }
  ]
}
```

### Common plist keys

| Key | Use case |
|-----|----------|
| `NSCameraUsageDescription` | Camera access |
| `NSMicrophoneUsageDescription` | Microphone access |
| `NSLocationWhenInUseUsageDescription` | Location (foreground) |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | Location (background) |
| `NSBluetoothAlwaysUsageDescription` | Bluetooth LE |
| `NSFaceIDUsageDescription` | Face ID / biometrics |
| `NSContactsUsageDescription` | Contacts access |
| `NSCalendarsUsageDescription` | Calendar access |
| `CFBundleURLTypes` | Custom URL schemes |
| `LSApplicationQueriesSchemes` | Queried URL schemes |
| `UIBackgroundModes` | Background execution modes |

---

## xcprivacy

Updates the `PrivacyInfo.xcprivacy` file for the target and build. By default
values are merged; set `replace: true` to overwrite the entire target object.

| Field | Required | Description |
|-------|----------|-------------|
| `entries` | yes | Array of privacy key-value objects |
| `replace` | no | `true` overwrites; `false` (default) merges |

**Conditional:** Yes

```json
"ios": {
  "xcprivacy": [
    {
      "replace": true,
      "entries": [{ "NSPrivacyTracking": [] }]
    },
    {
      "replace": false,
      "entries": [
        {
          "NSPrivacyAccessedAPITypes": {
            "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryUserDefaults",
            "NSPrivacyAccessedAPITypeReasons": ["CA92.1"]
          }
        }
      ]
    }
  ]
}
```

---

## entitlements

Updates the `.entitlements` file for the target and build. This is an **object**
(not an array). By default values are merged; set `replace: true` to overwrite
the entire target object.

| Field | Required | Description |
|-------|----------|-------------|
| `entries` | yes | Array of entitlement key-value objects |
| `replace` | no | `true` overwrites; `false` (default) merges |

**Conditional:** Yes

```json
"ios": {
  "entitlements": {
    "replace": false,
    "entries": [
      { "aps-environment": "production" },
      { "keychain-access-groups": ["$(AppIdentifierPrefix)com.example.app"] },
      { "com.apple.security.application-groups": ["group.com.example.app"] }
    ]
  }
}
```

### Common entitlement keys

| Key | Use case |
|-----|----------|
| `aps-environment` | Push notifications (`"development"` or `"production"`) |
| `com.apple.security.application-groups` | Shared data between app and extensions |
| `keychain-access-groups` | Shared keychain between apps |
| `com.apple.developer.associated-domains` | Universal links, Handoff |
| `com.apple.developer.nfc.readersession.formats` | NFC reading |
| `com.apple.developer.siri` | SiriKit integration |

---

## frameworks

Adds frameworks to the Xcode project.

| Field | Required | Description |
|-------|----------|-------------|
| `name` | yes | Framework name (e.g. `"AudioToolbox.framework"`) |
| `customFramework` | no | Whether this is a custom (non-system) framework |
| `link` | no | Whether to link the framework |
| `embed` | no | Whether to embed the framework |

**Conditional:** Yes

```json
"ios": {
  "frameworks": [
    { "name": "AudioToolbox.framework" },
    { "name": "CoreServices.framework" },
    { "name": "MyCustom.framework", "customFramework": true, "embed": true }
  ]
}
```

---

## json

Modifies the content of JSON files within the iOS project. `file` is relative
to the iOS project root.

| Operation | Description |
|-----------|-------------|
| `set` | Overrides the specified element entirely |
| `merge` | Deep-merges the provided values into existing content |

**Conditional:** Yes

```json
"ios": {
  "json": [
    {
      "file": "google-services.json",
      "set": { "project_info": { "project_id": "MY_ID" } }
    },
    {
      "file": "google-services.json",
      "merge": { "data": { "field": "MY_FIELD" } }
    }
  ]
}
```

---

## xml

Modifies arbitrary XML files within the iOS project.

| Operation | Required fields | Description |
|-----------|----------------|-------------|
| `attrs` | `target` | Set or replace attributes on the target element |
| `merge` | `target` | Merge XML tree (matches on attributes, appends new children) |
| `inject` | `target` | Inject XML inside the target |
| `replace` | `target` | Replace the target node with the provided XML string |
| `deleteAttributes` | `target` | Delete the listed attributes from the target element |
| `delete` | — | Delete nodes matching an XPath expression (no `target` field) |

**Conditional:** Yes

```json
"ios": {
  "xml": [
    {
      "file": "App/config.xml",
      "target": "entries/field",
      "merge": "<field>\n  <string>Value</string>\n</field>\n"
    }
  ]
}
```

---

## copy

Copies files, directories, or URLs into the iOS project. Paths are relative to
the iOS project root.

> **Skill maintainer context — do not relay these details to users:**
> ODC/MABS appends a hash to resource filenames at deploy time, making
> user-supplied file paths unpredictable. Use `copy` only with hardcoded paths
> inside the plugin bundle or external URLs. If the source file is provided by
> the consuming application at runtime, a Capacitor hook is more appropriate.

| Field | Description |
|-------|-------------|
| `src` | Source path (relative to project root) or URL |
| `dest` | Destination path relative to the iOS project root |

**Conditional:** Yes

```json
"ios": {
  "copy": [
    {
      "src": "../firebase/GoogleService-Info.plist",
      "dest": "App/GoogleService-Info.plist"
    },
    {
      "src": "https://example.com/file.png",
      "dest": "App/Assets/file.png"
    }
  ]
}
```

---

## strings

Updates `.strings` files for localization. Use `set` for inline key-value pairs
or `setFromJson` to load values from a JSON file.

| Field | Required | Description |
|-------|----------|-------------|
| `file` | yes | Path to the `.strings` file |
| `set` | one of | Object of key-value string pairs to add or update |
| `setFromJson` | one of | Path to a JSON file whose key-value pairs are applied |

**Conditional:** Yes

```json
"ios": {
  "strings": [
    {
      "file": "App/Localizable.strings",
      "set": { "Insert Element": "Insert Element" }
    },
    {
      "file": "App/Localizable.strings",
      "setFromJson": "lang/en.json"
    }
  ]
}
```

---

## xcconfig

Updates `.xcconfig` files with build configuration key-value pairs.

| Field | Required | Description |
|-------|----------|-------------|
| `file` | yes | Path to the `.xcconfig` file |
| `set` | yes | Object of key-value pairs to add or update |

**Conditional:** Yes

```json
"ios": {
  "xcconfig": [
    {
      "file": "App/Config.xcconfig",
      "set": { "PRODUCT_NAME": "$NAME" }
    }
  ]
}
```

---

## code

Adds source files to the project or patches existing source files. Three
variants — use exactly one per entry. Note: iOS and Android `code` action
shapes differ — iOS `source` does not require `targetDir`.

| Variant | Fields | Description |
|---------|--------|-------------|
| Add source file | `source` + optional `compilerFlags` | Adds a source file to the Xcode project |
| Replace in file | `file` + `target` + `replace` | Replaces the matched target string in the file |
| Apply patch file | `file` + `patchFile` | Applies a `.patch` file to the specified source file |

> **Skill maintainer context — do not relay these details to users:**
>
> **Prefer other actions over `code`** — `plist`, `entitlements`, `buildSettings`,
> `buildPhases`, and `xcconfig` cover most iOS native requirements without
> touching source files. Only use `code` when there is no config-level
> alternative.
>
> **Avoid `patchFile`** — ODC/MABS appends a hash to deployed resource files
> (e.g., `my.patch` → `my__LoeSKZNXr0G1p13MNxJoQw.patch`), making the filename
> unpredictable and causing build failures. The `.patch` extension may also be
> unsupported in the ODC resource file list. Use `file`+`target`+`replace` for
> simple substitutions instead. For complex native code changes that cannot be
> expressed as a string replacement, a Capacitor hook is more reliable.
>
> **File paths are not searched** — the `file` field must be the full path
> relative to the iOS project root (e.g., `App/AppDelegate.swift`).

**Conditional:** Yes

```json
"ios": {
  "code": [
    {
      "source": "files/CustomBridge.swift"
    },
    {
      "source": "files/FooBarLib.a",
      "compilerFlags": "-fno-objc-arc"
    },
    {
      "file": "App/AppDelegate.swift",
      "target": "/import Capacitor/",
      "replace": "import Capacitor\nimport WatchConnectivity\n"
    },
    {
      "file": "App/AppDelegate.swift",
      "patchFile": "patches/ChangeAppDelegate.patch"
    }
  ]
}
```

---

## tar

Applies tar operations on files within the iOS project.

> **Skill maintainer context — do not relay these details to users:**
> ODC/MABS appends a hash to resource filenames at deploy time, making
> user-supplied file paths unpredictable. Use `tar` only when `src` is a
> hardcoded path inside the plugin bundle. If the archive is provided by the
> consuming application, a Capacitor hook is more appropriate.

| Field | Description |
|-------|-------------|
| `src` | Path to the tar file |
| `dest` | Target directory for the operation |
| `action` | Tar command: `"c"` (create), `"r"` (append), `"u"` (update), `"x"` (extract) |

**Conditional:** Yes

```json
"ios": {
  "tar": [
    {
      "src": "files/FooBar.tar",
      "dest": "files/FooBar",
      "action": "x"
    }
  ]
}
```
