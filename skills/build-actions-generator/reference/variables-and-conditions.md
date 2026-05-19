# Variables & Conditions

## Variables

Variables are optional inputs that developers can set from ODC Studio. They
allow the same build action to behave differently across apps.

```json
"variables": {
  "APP_NAME": {
    "type": "string",
    "default": ""
  },
  "TIMEOUT": {
    "type": "number",
    "default": 30
  },
  "ENABLE_DEBUG": {
    "type": "boolean",
    "default": false
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | yes | `"string"`, `"number"`, or `"boolean"` |
| `default` | any | no | Fallback value used when the developer does not set the variable. Recommended in most cases so the build action has sensible out-of-the-box behavior. Without a default, the developer must supply a value or the build will fail. |

**Usage in values:** Reference variables with `$VAR_NAME` anywhere in string
values inside the JSON.

```json
"attrs": { "android:name": "com.example.$APP_NAME" }
```

## Conditions

Conditions control whether an individual action runs. Add a `condition` field
to any action entry (except `displayName`, `productName`, and `appName` — see
platform reference files) using function-style expressions:

| Operator | Meaning | Example |
|----------|---------|---------|
| `eq(a, b)` | equal | `eq($MODE, "prod")` |
| `ne(a, b)` | not equal | `ne($ENV, "dev")` |
| `gt(a, b)` | greater than | `gt($VERSION, 10)` |
| `ge(a, b)` | greater than or equal | `ge($COUNT, 0)` |
| `lt(a, b)` | less than | `lt($TIMEOUT, 60)` |
| `le(a, b)` | less than or equal | `le($LEVEL, 5)` |

Arguments can be variable references (`$VAR_NAME`) or literal values:

```json
{
  "file": "AndroidManifest.xml",
  "condition": "ge($EXAMPLE_NUMBER, 0)",
  "target": "manifest/application",
  "attrs": { "android:name": "com.example.$APP_NAME" }
}
```

---

## See also: supplying variable values in ODC

Variables declared here are supplied at build time via the `parameters` block in the extensibility configuration. Values in `parameters` can be hardcoded literals or extensibility setting references (`$extensibilitySettings.SettingName`). The plugin developer creates extensibility settings in ODC Studio and references them in `parameters`; the consuming app then sets their values in ODC Portal — without hardcoding anything in the JSON.

See **[reference/extensibility-configuration.md](extensibility-configuration.md)** for the `parameters` contract and how to create extensibility settings in ODC Studio.
