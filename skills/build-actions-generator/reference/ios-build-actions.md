# iOS Build Actions Reference

All iOS build action types supported in the ODC build actions JSON schema.
These go under `platforms.ios` in your `buildAction.json`.

---

## plist

Modifies `Info.plist`. Accepts an array of patch entries.

```json
"ios": {
  "plist": [
    { "replace": false, "entries": [ { "NSKey": "value" } ] }
  ]
}
```

### Entry fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `replace` | boolean | yes | `true` replaces existing keys; `false` merges without overwriting |
| `entries` | array | yes | Array of plist key-value objects to add or update |

**Add a usage description:**

```json
{
  "replace": false,
  "entries": [
    { "NSCameraUsageDescription": "This app needs camera access to scan QR codes." }
  ]
}
```

**Add multiple usage descriptions in one entry:**

```json
{
  "replace": false,
  "entries": [
    { "NSLocationWhenInUseUsageDescription": "We need your location for delivery tracking." },
    { "NSBluetoothAlwaysUsageDescription": "We use Bluetooth to communicate with nearby devices." }
  ]
}
```

**Register a custom URL scheme:**

```json
{
  "replace": false,
  "entries": [
    {
      "CFBundleURLTypes": [
        {
          "CFBundleURLSchemes": ["myapp"]
        }
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
| `NSLocationAlwaysUsageDescription` | Location (background) |
| `NSBluetoothAlwaysUsageDescription` | Bluetooth LE |
| `NSFaceIDUsageDescription` | Face ID / biometrics |
| `NSContactsUsageDescription` | Contacts access |
| `NSCalendarsUsageDescription` | Calendar access |
| `CFBundleURLTypes` | Custom URL schemes |
| `LSApplicationQueriesSchemes` | Queried URL schemes |
| `UIBackgroundModes` | Background execution modes |

---

## entitlements

Adds or modifies entitlement keys. Required for capabilities provisioned
through the Apple Developer portal (push notifications, app groups, etc.).

```json
"ios": {
  "entitlements": [
    {
      "replace": false,
      "entries": [
        { "aps-environment": "production" }
      ]
    }
  ]
}
```

### Entry fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `replace` | boolean | yes | `true` replaces existing keys; `false` merges without overwriting |
| `entries` | array | yes | Entitlement key-value pairs |

**Enable push notifications:**

```json
{
  "replace": false,
  "entries": [
    { "aps-environment": "production" }
  ]
}
```

Use `"development"` for debug builds, `"production"` for release.

**Add an app group:**

```json
{
  "replace": false,
  "entries": [
    { "com.apple.security.application-groups": ["group.com.example.app"] }
  ]
}
```

**Enable keychain sharing:**

```json
{
  "replace": false,
  "entries": [
    { "keychain-access-groups": ["$(AppIdentifierPrefix)com.example.app"] }
  ]
}
```

**Add associated domains (universal links / Handoff):**

```json
{
  "replace": false,
  "entries": [
    { "com.apple.developer.associated-domains": ["applinks:example.com"] }
  ]
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

## displayName

Overrides the app display name shown on the device home screen. This is a
**string**, not an array, placed directly under the `ios` platform key.
Supports variable substitution with `$VAR_NAME`.

```json
"ios": {
  "displayName": "My App"
}
```

**With variable substitution:**

```json
"ios": {
  "displayName": "$APP_NAME"
}
```

---

## code

Injects or replaces native iOS (Swift/Objective-C) code at a marked location.
Use for changes that cannot be expressed as plist or entitlement patches.

```json
"ios": {
  "code": [
    {
      "file": "App/AppDelegate.swift",
      "target": "// BUILD_ACTION_INJECT_HERE",
      "inject": "import ExampleSDK\n"
    }
  ]
}
```

### Entry fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `file` | string | yes | Source file path relative to the iOS project |
| `target` | string | yes | Marker string or pattern to locate the injection point |
| `inject` | string | no* | Code string to insert at the target |
| `replace` | string | no* | Code string to replace the target match |
| `condition` | string | no | Skip this entry if the expression evaluates to false |

*One of `inject` or `replace` required.

**Inject an import at the top of AppDelegate:**

```json
{
  "file": "App/AppDelegate.swift",
  "target": "// BUILD_ACTION_INJECT_HERE",
  "inject": "import MySDK\n"
}
```

**Replace an old import:**

```json
{
  "file": "App/AppDelegate.swift",
  "target": "import OldSDK",
  "replace": "import NewSDK"
}
```
