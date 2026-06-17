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
platform reference files) using function-style expressions.

**`condition` must be a string.** Never use an object, array, or any other type — the validator will reject it. The only valid form is the function-style string syntax shown below.

These are all **invalid** and will fail validation:

```json
"condition": { "operator": "ne", "left": "$COLOR", "right": "" }
"condition": { "op": "ne", "arg1": "$COLOR", "arg2": "" }
"condition": ["ne", "$COLOR", ""]
```

This is the **only valid form**:

```json
"condition": "ne($COLOR, red)"
```

> **Do not quote string literals in conditions.** The build system performs variable interpolation before parsing the condition — `$VAR` is replaced with its raw value first, then the expression is parsed. Any surrounding quote characters you write become part of the parsed argument string. For example, `eq($MODE, "prod")` after interpolation becomes `eq(prod, "prod")` — the parser sees `args[1]` as `"prod"` (with literal quote characters), which never equals `prod`, so the condition is always false. Write bare values: `eq($MODE, prod)`.

| Operator | Meaning | Example |
|----------|---------|---------|
| `eq(a, b)` | equal | `eq($MODE, prod)` |
| `ne(a, b)` | not equal | `ne($ENV, dev)` |
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

### Limitation: empty string comparisons are not supported

Conditions cannot compare a variable against an empty string literal (`''`). The following is **invalid** and will fail validation:

```json
"condition": "ne($SOME_STRING, '')"
```

This is only a problem when a string variable has an empty-string default — if the default is a meaningful value, the condition is unnecessary entirely.

**Correct pattern — use a boolean flag instead.**

When the intent is "apply this action only if the user provided a value", add a companion boolean variable and condition on that:

```json
"variables": {
  "ENABLE_NOTIFICATION_COLOR": {
    "type": "boolean",
    "default": false
  },
  "NOTIFICATION_COLOR": {
    "type": "string",
    "default": ""
  }
}
```

```json
{
  "condition": "eq($ENABLE_NOTIFICATION_COLOR, true)",
  "resFile": "values/strings.xml",
  "target": "resources/string[@name=\"notification_color\"]",
  "replace": "<string name=\"notification_color\">$NOTIFICATION_COLOR</string>\n"
}
```

The developer sets `ENABLE_NOTIFICATION_COLOR` to `true` in ODC Studio when they also supply a value for `NOTIFICATION_COLOR`. When `ENABLE_NOTIFICATION_COLOR` is `false` (the default), the action is skipped entirely.

---

## See also: supplying variable values in ODC

Variables declared here are supplied at build time via the `parameters` block in the extensibility configuration. Values in `parameters` can be hardcoded literals or extensibility setting references (`$extensibilitySettings.SettingName`). The plugin developer creates extensibility settings in ODC Studio and references them in `parameters`; the consuming app then sets their values in ODC Portal — without hardcoding anything in the JSON.

See **[references/extensibility-configuration.md](extensibility-configuration.md)** for the `parameters` contract and how to create extensibility settings in ODC Studio.
