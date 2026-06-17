<!-- Source: https://github.com/OutSystems/docs-odc/blob/main/src/eap/building-apps/mobile/build-actions-android.md -->
<!-- Raw (for sync): https://raw.githubusercontent.com/OutSystems/docs-odc/main/src/eap/building-apps/mobile/build-actions-android.md -->
<!-- Last verified: 2026-05-18 -->

# Android Build Actions Reference

All Android build action types supported in the ODC build actions JSON schema.
All actions go under `platforms.android` in your `buildAction.json`. The full
wrapper structure is always required:

```json
{
  "platforms": {
    "android": {
      ...actions here...
    }
  }
}
```

Examples in this file show only the `"android": { ... }` portion for brevity.

All actions except `appName` support an optional `condition` field for
conditional execution — see the Variables & Conditions section in SKILL.md.

---

## appName

Sets the Android app display name by updating the `label` attribute in
`AndroidManifest.xml`, or the strings resource value when a resource reference
is used in the manifest.

**Type:** `string` | **Conditional:** No

```json
"android": {
  "appName": "My App Name"
}
```

---

## manifest

Modifies `AndroidManifest.xml`. Accepts an array of patch entries, each
requiring a `file` field. Exactly one operation per entry.

| Operation | Required fields | Description |
|-----------|----------------|-------------|
| `attrs` | `target` | Set or replace attributes on the target element |
| `merge` | `target` | Merge an XML string into the target (deduplication-safe) |
| `inject` | `target` | Inject an XML string into the target (allows duplicates) |
| `deleteAttributes` | `target` | Delete the listed attributes from the target element |
| `delete` | — | Delete nodes matching an XPath expression (no `target` field) |

`target` is an XPath-like path (e.g. `"manifest"`, `"manifest/application"`).
`delete` uses a full XPath expression directly (e.g. `"//intent-filter"`).

> **`merge` fragments must be rooted at the target element.** The fragment's root tag must match the `target` node — e.g. `target: "manifest"` → root is `<manifest>`, `target: "manifest/application"` → root is `<application>`. Passing a bare child element (e.g. a naked `<uses-permission />` with `target: "manifest"`) causes `xmldom` to attempt inserting it as a sibling to the document root, which is illegal XML and produces a hierarchy error at build time.

> **`attrs` values must be strings.** Boolean and number variable references are not valid in `attrs` and will fail validation. To set an attribute to a boolean or numeric value, use `inject` or `merge` with the full XML element instead.

```json
"android": {
  "manifest": [
    {
      "file": "AndroidManifest.xml",
      "target": "manifest/application",
      "attrs": { "android:name": "com.example.MyApplication" }
    },
    {
      "file": "AndroidManifest.xml",
      "target": "manifest",
      "merge": "<manifest>\n  <uses-permission android:name=\"android.permission.CAMERA\" />\n</manifest>"
    },
    {
      "file": "AndroidManifest.xml",
      "target": "manifest/application",
      "inject": "<activity android:name=\"com.example.AuthActivity\" />\n"
    },
    {
      "file": "AndroidManifest.xml",
      "target": "manifest/application",
      "deleteAttributes": ["android:name"]
    },
    {
      "file": "AndroidManifest.xml",
      "delete": "//intent-filter"
    }
  ]
}
```

---

## gradle

Modifies Gradle build files. Accepts an array of patch entries.

> **Skill maintainer context — do not relay these details to users:**
> Never generate `gradle` build actions to replicate content already present in
> the plugin's own Gradle file. A `<framework src="..." type="gradleReference">`
> element in `plugin.xml` causes Capacitor CLI to merge that file into the
> project during sync — its dependencies, repositories, and plugin declarations
> do not need a build action. Only generate `gradle` build actions for entries
> the plugin explicitly documents as app-level setup steps that go into the root
> `build.gradle` or `app/build.gradle` and are absent from the plugin's own
> file. See the `<framework>` and `<preference>` sections in
> [references/cordova-plugin-scanning.md](references/cordova-plugin-scanning.md)
> for the full decision rules.

**`insert`** — inserts new Gradle content at the target location:
- `insert` as a **string**: inserts verbatim Groovy/Gradle text
- `insert` as an **array of objects**: each object is inserted as either a
  method call (`method arg`, default) or a variable assignment (`var = value`)
  controlled by `insertType: "method" | "variable"` (default: `"method"`)

**`replace`** — replaces existing key-value pairs at the target location.

**`target`** mirrors the Gradle DSL hierarchy as a nested object; use `null`
as a block value (not a leaf). Set `target: null` to insert at the top level
of the file.

```json
"android": {
  "gradle": [
    {
      "file": "build.gradle",
      "target": { "buildscript": null },
      "insert": [{ "classpath": "'org.javassist:javassist:3.27.0-GA'" }]
    },
    {
      "file": "build.gradle",
      "target": { "allprojects": { "repositories": null } },
      "insert": [
        {
          "maven": [
            { "url": "https://example.com" },
            { "name": "MyFeed" }
          ]
        }
      ]
    },
    {
      "file": "variables.gradle",
      "target": { "ext": null },
      "insertType": "variable",
      "insert": [{ "firebaseMessagingVersion": "20.0.6" }]
    },
    {
      "file": "app/build.gradle",
      "target": null,
      "insert": "apply plugin: 'com.example.plugin'\n"
    },
    {
      "file": "app/build.gradle",
      "target": { "android": { "buildTypes": { "release": null } } },
      "replace": { "minifyEnabled": true }
    }
  ]
}
```

---

## res

Creates new resource files under the `res` folder of the Android project.

| Field | Required | Description |
|-------|----------|-------------|
| `path` | yes | Subfolder under `res` (e.g. `"raw"`, `"drawable"`, `"values"`) |
| `file` | yes | Output filename |
| `text` | one of | Inline file content as a string (supports `$VAR_NAME` substitution) |
| `source` | one of | Local path or URL to copy from |

```json
"android": {
  "res": [
    {
      "path": "raw",
      "file": "auth_config.json",
      "text": "{\n  \"client_id\": \"$CLIENT_ID\"\n}\n"
    },
    {
      "path": "drawable",
      "file": "icon.png",
      "source": "../common/icon.png"
    },
    {
      "path": "drawable",
      "file": "remote-icon.png",
      "source": "https://example.com/icon.png"
    }
  ]
}
```

---

## json

Modifies the content of JSON files within the Android project.

| Operation | Description |
|-----------|-------------|
| `set` | Overrides the specified element entirely |
| `merge` | Deep-merges the provided values into the existing content |

```json
"android": {
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

Modifies arbitrary XML files within the Android project. Same operations as
`manifest` plus `replace`. Use `file` for project-relative paths or `resFile`
for paths relative to the `res` folder.

> **Do not use `xml` for `AndroidManifest.xml` changes — use the `manifest` action instead.** `manifest` validates attribute value types at parse time; `xml` does not, so type errors (e.g. boolean in `attrs`) will slip through validation silently and may produce incorrect output at build time.

| Operation | Required fields | Description |
|-----------|----------------|-------------|
| `attrs` | `target` | Set or replace attributes on the target element |
| `merge` | `target` | Merge XML tree (matches on attributes, appends new children) |
| `inject` | `target` | Inject XML inside the target |
| `replace` | `target` | Replace the target node with the provided XML string |
| `deleteAttributes` | `target` | Delete the listed attributes from the target element |
| `delete` | — | Delete nodes matching an XPath expression (no `target` field) |

```json
"android": {
  "xml": [
    {
      "file": "app/network_config.xml",
      "target": "network-security-config",
      "merge": "<domain-config cleartextTrafficPermitted=\"true\"><domain includeSubdomains=\"true\">example.com</domain></domain-config>\n"
    },
    {
      "resFile": "values/strings.xml",
      "target": "resources/string[@name=\"app_name\"]",
      "replace": "<string name=\"app_name\">My App</string>\n"
    }
  ]
}
```

---

## copy

Copies files, directories, or URLs into the Android project. All paths are
relative to the Android project root.

> **Skill maintainer context — do not relay these details to users:**
> ODC/MABS appends a hash to resource filenames at deploy time, making
> user-supplied file paths unpredictable. Use `copy` only with hardcoded paths
> inside the plugin bundle or external URLs. If the source file is provided by
> the consuming application at runtime, a Capacitor hook is more appropriate.

| Field | Description |
|-------|-------------|
| `src` | Source path (relative to project root) or URL |
| `dest` | Destination path relative to the Android project root |

```json
"android": {
  "copy": [
    {
      "src": "../firebase/google-services.json",
      "dest": "app/google-services.json"
    },
    {
      "src": "https://example.com/file.png",
      "dest": "app/src/main/res/drawable/file.png"
    }
  ]
}
```

---

## code

Adds source files to the project or patches existing source files. Three
variants — use exactly one per entry:

| Variant | Fields | Description |
|---------|--------|-------------|
| Copy source file | `source` + `targetDir` | Copies a source file into the specified directory |
| Replace in file | `file` + `target` + `replace` | Replaces the matched target string in the file |
| Apply patch file | `file` + `patchFile` | Applies a `.patch` file to the specified source file |

`target` in the replace variant is a string or regex pattern identifying the
text to replace.

> **Skill maintainer context — do not relay these details to users:**
>
> **Prefer other actions over `code`** — `manifest`, `gradle`, and `xml` cover
> most Android native requirements without touching source files. Only use `code`
> when there is no config-level alternative.
>
> **Avoid `patchFile`** — ODC/MABS appends a hash to deployed resource files
> (e.g., `my.patch` → `my__LoeSKZNXr0G1p13MNxJoQw.patch`), making the filename
> unpredictable and causing build failures. The `.patch` extension may also be
> unsupported in the ODC resource file list. Use `file`+`target`+`replace` for
> simple substitutions instead. For complex native code changes that cannot be
> expressed as a string replacement, a Capacitor hook is more reliable.
>
> **File paths are not searched** — the `file` field must be the full path
> relative to the Android project root (e.g.,
> `app/src/main/java/com/example/myapp/MainActivity.java`). For plugins, the
> consuming app's package name is part of the path and must be passed as a
> variable.

```json
"android": {
  "code": [
    {
      "source": "files/MyClass.java",
      "targetDir": "src/com/example"
    },
    {
      "file": "app/src/main/java/com/example/myapp/MainActivity.java",
      "target": "/import com.getcapacitor.BridgeActivity;/",
      "replace": "import com.getcapacitor.BridgeActivity;\nimport com.example.MyFragment;\n"
    },
    {
      "file": "MainActivity.java",
      "patchFile": "patches/MainActivity.patch"
    }
  ]
}
```

---

## tar

Applies tar operations on files within the Android project.

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

```json
"android": {
  "tar": [
    {
      "src": "files/archive.tar",
      "dest": "files/extracted",
      "action": "x"
    }
  ]
}
```
