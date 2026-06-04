# Scenario Detection

Read this file at the very start of every `plugin-unifier` invocation, before
inspecting any source or proposing any API.

---

## Three Scenarios

### Scenario 1 — Both Plugins Are New

No existing Cordova or Capacitor repo for this plugin.

**How to establish the API spec:**

- If the user has provided a list of methods, option types, and return types →
  use that as the spec.
- If the user has only provided a plugin name → infer a sensible default API
  based on the plugin's domain and Capacitor community conventions. Present the
  proposed API and ask for confirmation before generating.

---

### Scenario 2 — One Plugin Exists, the Other Does Not

Either `cordova-outsystems-{name}` or `capacitor-{name}` exists, but not both.

**If the existing plugin is Cordova:**

1. Invoke `cordova-plugin-migrator` to analyze the Cordova plugin's API surface.
   The migrator reads `plugin.xml`, `www/js/{name}.js`, and the native bridge
   classes and returns the full method list with parameter and return shapes.
2. Extract: method names, parameter keys and types, return value shapes.

**If the existing plugin is Capacitor:**

1. Read `src/definitions.ts` — the TypeScript interface is the authoritative API
   contract.
2. Extract: interface name, method names, parameter types, return types, enums.

**In both cases:**

3. Present the extracted API to the user as the proposed spec.
4. Ask: *"Are there any methods you'd like to remove, rename, or change before I
   generate?"*
5. Wait for confirmation or changes, then proceed with the agreed spec.

Generate both repos fresh. If the spec is unchanged from the existing plugin,
only generate the missing repo. If the spec changed, regenerate both.

---

### Scenario 3 — Both Plugins Exist but APIs Are Divergent

Both `capacitor-{name}` and `cordova-outsystems-{name}` exist but their APIs
have diverged — different method names, different option shapes, or methods that
exist in one but not the other.

**How to establish the unified spec:**

1. Invoke `cordova-plugin-migrator` on the Cordova plugin to extract its API
   surface.
2. Read `src/definitions.ts` from the Capacitor plugin.
3. Produce a side-by-side comparison, categorising each method as:
   - ✅ **In both** — same name, same signature → keep as-is.
   - ⚠️ **In both, but signature differs** → flag the conflict, show both
     versions, ask the user to decide or provide a blend.
   - ➕ **Only in Capacitor** → ask: keep, drop, or rename?
   - ➕ **Only in Cordova** → ask: keep, drop, or rename?
4. Present the full comparison to the user. **Do NOT proceed until the user has
   resolved every conflict and confirmed the unified spec.**
5. The developer may also provide further context about the OutSystems Plugin API
   — for example, if the OML exposes a simplified API surface compared to the
   underlying plugins. Incorporate any such input into the confirmed spec before
   generating.
6. Once confirmed, generate both repos fresh from the unified spec.

**Important:** This scenario requires the most human input. Do not guess or
auto-resolve conflicts — always surface them explicitly. The unified API is a
deliberate design choice, not an automatic merge.

---

## API Spec Confirmation Format

Before writing any files, present the final agreed API to the user:

```
Plugin: {Name}
npm package: @capacitor/{plugin}   (default — confirm or override before generating)
Capacitor repo: capacitor-{plugin}
Cordova repo:   cordova-outsystems-{plugin}
Methods:
  - methodName(options: MethodOptions): Promise<MethodResult>
  - checkPermissions(): Promise<PermissionStatus>
  - requestPermissions(permissions?: PermissionType[]): Promise<PermissionStatus>

Types:
  - MethodOptions: { key: type, ... }
  - MethodResult: { key: type, ... }
  - PermissionType: 'permA' | 'permB'
  - PermissionStatus: { permA: PermissionState, permB: PermissionState }
```

The **npm package name defaults to `@capacitor/{plugin}` but must be confirmed**
— present the default and let the developer accept or override before
generating. Never silently invent a different scope (e.g. `@outsystems/…`). The
developer may override (unscoped `capacitor-{plugin}` or a scope they control;
`@capacitor` is Ionic-owned and unpublishable by third parties). See
`references/unified-structure.md` "npm package name".

If the source plugin does not already expose `checkPermissions()` /
`requestPermissions()`, **ask the developer whether to expose explicit
permission methods or request permissions implicitly inside each method** — do
not assume the explicit methods. The `cordova-plugin-migrator` baseline adds
them by convention, but many legacy plugins request permissions implicitly, and
that may be the intended behavior. Default to the explicit methods, present it
as a default, and apply the chosen model to both plugins.

Ask: *"Does this look right? I'll generate both plugins from this spec."*

Only proceed once the user confirms.
