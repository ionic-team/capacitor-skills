<!-- Source (app schema): https://github.com/OutSystems/docs-odc/blob/main/src/eap/building-apps/mobile/extensibility-configurations/extensibility-app-reference.md -->
<!-- Source (library schema): https://github.com/OutSystems/docs-odc/blob/main/src/eap/building-apps/mobile/extensibility-configurations/extensibility-lib-reference.md -->
<!-- Last verified: 2026-05-19 -->

# ODC Extensibility Configuration

The extensibility configuration is a JSON document set in ODC Studio that wires native configuration into a mobile app or library. It is distinct from `buildAction.json` — the build action file defines *what* transformations to apply to the native project, while the extensibility configuration defines *which* files to run, *what values* to supply to their variables, and *which permissions* the plugin requires.

Extensibility configurations exist across OutSystems platforms and MABS versions. This document covers only the ODC schema with MABS 12 or later, because `buildConfigurations.buildAction` — the part that connects build action files — is only available in that context. O11 and pre-12 MABS versions use a different extensibility schema that does not support build actions or Capacitor, therefore is out of scope for this build actions skill.

## Placement in ODC Studio

| Context | Location |
|---------|----------|
| Mobile App | App > Edit app properties > **Extensibility** tab |
| Mobile Library (plugin) | Library > Edit library properties > **Extensibility** tab |

Both apps and libraries have their own extensibility configuration. They use different top-level schemas.

## Schema by context

| Context | First section | Second section |
|---------|---------------|----------------|
| App | `appConfigurations` | `buildConfigurations` |
| Library (plugin) | `pluginConfigurations` | `buildConfigurations` |

Both sections are optional. Both contexts share the same `buildConfigurations` shape.

---

## Extensibility settings

Extensibility settings are named, build-time values defined in ODC Studio and managed in ODC Portal. They are the standard mechanism for supplying variable values that would otherwise need to be hardcoded in the extensibility configuration JSON.

> **Extensibility settings vs. app settings**: ODC app settings (`Settings.<Name>`) are runtime values used in server/client actions. Extensibility settings are build-time values used only in the extensibility configuration JSON. Do not confuse the two.

### Creating an extensibility setting

In ODC Studio, open the app or library **Extensibility** tab. In the context pane:

1. Right-click **Extensibility Settings** folder → **Add Extensibility Setting**
2. Set the **Name**, **Description**, and **Data Type** (examples are Text, Boolean, Integer, Decimal, Binary)
3. In case of a sensitive value like an API Key or Token, or a file containing sensitive data, set **Is Secret** to True. This makes it so that the setting value is masked and not readable in ODC Portal. If not a sensitive value (e.g. a usage description for plist), leave it as False. Note that secret settings cannot have a default value — the developer must explicitly supply the value in ODC Portal before generating a mobile package; there is no fallback.
4. Reference the setting in the extensibility JSON as `$extensibilitySettings.SettingName`

### Setting types

| Type | Use for |
|------|---------|
| Text | String values: API keys, client IDs, URLs, usage descriptions |
| Boolean | True/false flags |
| Integer | Whole-number values: timeouts, port numbers |
| Decimal | Fractional numeric values |
| Binary | Files: `GoogleService-Info.plist`, `google-services.json`, custom certificates |

Binary settings are used as `source` values in `buildConfigurations.resources` to copy user-supplied files into the native project. All other types (text, boolean, integer, decimal) can be referenced in `parameters` via `$extensibilitySettings.SettingName`.

### Using extensibility settings to supply build action variable values

The `parameters` block accepts extensibility setting references. This is the recommended approach when the value differs between environments or should not be hardcoded in the JSON:

```json
{
  "buildConfigurations": {
    "buildAction": {
      "config": "$resources.buildAction.json",
      "parameters": {
        "CLIENT_ID": "$extensibilitySettings.OAuthClientId",
        "APP_SCHEME": "$extensibilitySettings.AppUrlScheme"
      }
    }
  }
}
```

The plugin developer creates `OAuthClientId` and `AppUrlScheme` as extensibility settings in ODC Studio; the consuming app then sets their values in ODC Portal — without editing the JSON.

> Extensibility binary settings are **not** supported in `buildAction.config` or `parameters`. Use `$resources.<filename>` for the build action file reference and text extensibility settings for string parameter values.

---

## buildConfigurations

Both app and library extensibility configs share this section. It governs build-time native project configuration.

### buildAction

Connects a `buildAction.json` file to the build process and supplies values for the variables it declares. See [SKILL.md](../SKILL.md) for the full build action authoring guide.

```json
{
  "buildConfigurations": {
    "buildAction": {
      "config": "$resources.buildAction.json",
      "parameters": {
        "CLIENT_ID": "com.example.myapp",
        "APP_SCHEME": "myapp",
        "ENABLE_DEBUG": false
      }
    }
  }
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `config` | Yes | Reference to the build action JSON file |
| `parameters` | No | Values for variables declared in the build action JSON |

#### config — referencing the build action file

`config` accepts any of the placeholder prefixes (see [Placeholder reference](#placeholder-reference)). The most common form is `"$resources.<filename>"`, which resolves to a resource added in ODC Studio with **Deploy Action** set to **Deploy to Target Directory**.

#### parameters — supplying variable values

Each key in `parameters` maps to a variable name declared in the `"variables"` block of the referenced `buildAction.json`. The value must match the declared type (`string`, `number`, or `boolean`).

```json
"parameters": {
  "CLIENT_ID": "com.example.myapp",
  "TIMEOUT": 30,
  "ENABLE_LOGS": true
}
```

Values can also reference ODC extensibility settings, allowing the parameter to be managed outside the JSON:

```json
"parameters": {
  "CLIENT_ID": "$extensibilitySettings.OAuthClientId"
}
```

**Required variables**: If a variable in `buildAction.json` declares no `default`, it must be supplied in `parameters`. If neither the library extensibility config nor the consuming app's extensibility config supplies the value, the build fails.

**Execution order**: When a library and its consuming app both define `buildConfigurations.buildAction`, the library's build action runs first, followed by the app's.

### resources

Copies files from an ODC setting, resource, or image reference into the native project at build time. This is the correct approach for developer-supplied files that build actions cannot reference (such as `GoogleService-Info.plist` or `google-services.json`).

```json
{
  "buildConfigurations": {
    "resources": {
      "ios": [
        {
          "source": "$extensibilitySettings.GoogleServiceInfoPlist",
          "target": "GoogleService-Info.plist"
        }
      ],
      "android": [
        {
          "source": "$extensibilitySettings.GoogleServicesJsonBinary",
          "target": "android/app/src/main/res/google-services.json"
        }
      ]
    }
  }
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `source` | Yes | Source file reference (see [Placeholder reference](#placeholder-reference)) |
| `target` | Yes | Destination path relative to the native platform root |

> **Android target paths** are relative to `android/`.
> **iOS target paths** are relative to `ios/App/App/`.
>
> `resources` copying happens **before** `cap sync`. Avoid targeting paths that are overwritten by sync.

> **For build action authors**: When a plugin requires a developer-supplied config file (e.g., Firebase config), document the setup as a `buildConfigurations.resources` entry in the README rather than a `copy` build action. The `resources` mechanism uses ODC extensibility settings to accept the file from the developer — build action `copy` cannot.

---

## Declaring permissions and iOS usage descriptions

> **Skill maintainer context — do not relay these details to users:**
> This section is reference material for the generated README and for understanding the ODC extensibility ecosystem. The skill **always** generates `manifest` build actions for Android permissions and `plist` build actions for iOS usage descriptions. It never substitutes extensibility configuration JSON for build actions. References to `pluginConfigurations.permissions` in this section describe an alternative that may be mentioned in the README under specific conditions (see SKILL.md README authoring rules) — they are not generated output.

A plugin can supply Android permissions and iOS usage description strings either via build actions (the default approach for this skill — `manifest` for Android, `plist` for iOS) or via `pluginConfigurations.permissions` in the library's extensibility configuration. Both are plugin-side mechanisms. The distinction is that `pluginConfigurations.permissions` additionally allows consuming apps to override the description text — useful for generic plugins deployed across many apps where each app may want different wording. The `appConfigurations.permissions` app-side mechanism is documented below for completeness; it is not the plugin author's concern.

### Library-level: pluginConfigurations.permissions

A library declares which Android permissions and iOS protected resources the plugin needs, along with default description text. The consuming app relies on these defaults; it can override them at the app level, but that is the exception rather than the rule.

#### Android

```json
{
  "pluginConfigurations": {
    "permissions": {
      "android": [
        "android.permission.CAMERA",
        "android.permission.RECORD_AUDIO"
      ]
    }
  }
}
```

Each entry is a fully qualified Android permission string. MABS injects these into the app's `AndroidManifest.xml` at build time.

#### iOS usage descriptions

```json
{
  "pluginConfigurations": {
    "permissions": {
      "ios": {
        "NSCameraUsageDescription": {
          "description": "Used for scanning barcodes."
        },
        "NSMicrophoneUsageDescription": {}
      }
    }
  }
}
```

Each key is an iOS usage description key (NSXxxUsageDescription). The value is an object with an optional `description` field.

| Value | Meaning |
|-------|---------|
| `{ "description": "Some text." }` | Provides a default description; consuming app can override it |
| `{}` | Declares the key as required with no default — consuming app **must** supply a value |

**Missing description**: If a key is declared with `{}` (no default) and neither the consuming app nor any other library provides a value, the key is absent from `Info.plist`. iOS will crash the app or deny access to the protected resource at runtime when it is first requested, depending on the API and OS version. The app may also be rejected at App Store submission if the binary uses the associated API without a corresponding usage description.

#### Combined example

```json
{
  "pluginConfigurations": {
    "permissions": {
      "android": [
        "android.permission.CAMERA"
      ],
      "ios": {
        "NSCameraUsageDescription": {
          "description": "Required for scanning."
        }
      }
    }
  }
}
```

### App-level: appConfigurations.permissions

Apps declare permissions directly or override values set by libraries. App-level values always take precedence over library-level values.

```json
{
  "appConfigurations": {
    "permissions": {
      "android": [
        "android.permission.CAMERA"
      ],
      "ios": {
        "NSCameraUsageDescription": "This app uses the camera to scan receipts."
      }
    }
  }
}
```

> **Note**: iOS usage descriptions at the app level are a plain `string` (not an object). This differs from the library-level format where the value is `{ "description": "..." }`.

### Resolution order for iOS usage descriptions

| Library declares | App provides | Result |
|-----------------|--------------|--------|
| `{ "description": "Default text." }` | — | Library default is used |
| `{ "description": "Default text." }` | `"App text."` | App value overrides library |
| `{}` | `"App text."` | App value is used |
| `{}` | — | Key absent from `Info.plist` — app crashes or denies access at runtime when the protected resource is accessed; may be rejected at App Store submission |

### Common iOS usage description keys

| Key | Protected resource |
|-----|--------------------|
| `NSCameraUsageDescription` | Camera |
| `NSMicrophoneUsageDescription` | Microphone |
| `NSLocationWhenInUseUsageDescription` | Location (foreground) |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | Location (background) |
| `NSBluetoothAlwaysUsageDescription` | Bluetooth LE |
| `NSFaceIDUsageDescription` | Face ID / biometrics |
| `NSContactsUsageDescription` | Contacts |
| `NSCalendarsUsageDescription` / `NSCalendarsFullAccessUsageDescription` | Calendar |
| `NSPhotoLibraryUsageDescription` | Photo library (read) |
| `NSPhotoLibraryAddUsageDescription` | Photo library (write) |
| `NFCReaderUsageDescription` | NFC |
| `NSHealthShareUsageDescription` | HealthKit (read) |
| `NSMotionUsageDescription` | Motion / accelerometer |

---

## Permissions vs. build actions

For plugin authors, both build actions and `pluginConfigurations.permissions` are plugin-side mechanisms — the plugin controls what is declared. Use the one that best fits the plugin's needs:

| Mechanism | Side | Use when |
|-----------|------|----------|
| `manifest` build action | Plugin | Android permissions — plugin controls the value directly |
| `plist` build action | Plugin | iOS usage descriptions — plugin controls the wording |
| `pluginConfigurations.permissions` | Plugin | Either platform — when apps should be able to override the description text, or when the plugin intentionally wants to require the consuming app to provide context-specific wording |
| `appConfigurations.permissions` | App | Consuming app adds or overrides permissions independently of the plugin — not relevant to plugin authors |

Build actions apply the plugin's value directly at build time. `pluginConfigurations.permissions` does the same but additionally exposes the description text for app-level override.

---

## Placeholder reference

Extensibility configuration values support these reference prefixes:

| Prefix | Resolves to |
|--------|-------------|
| `$resources.<filename>` | A resource added in ODC Studio with Deploy Action: Deploy to Target Directory |
| `$extensibilitySettings.<SettingName>` | An ODC extensibility setting (text or binary) |
| `$images.<ImageName>` | An image added to the ODC app |

---

## Cross-references

- **Build action variables** — [references/variables-and-conditions.md](variables-and-conditions.md): how variables are declared in `buildAction.json` (the plugin side of the `parameters` contract)
- **Android build actions** — [references/android-build-actions.md](android-build-actions.md): `manifest` action for permissions; `gradle` for dependencies
- **iOS build actions** — [references/ios-build-actions.md](ios-build-actions.md): `plist` for usage descriptions; `entitlements` for capabilities
