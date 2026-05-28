# Cordova Hooks Migration Strategy

This reference provides detailed guidance on migrating Cordova plugin hooks to Capacitor using a three-tiered approach.

## Contents

- [Three-Tiered Approach](#three-tiered-approach)
- [Tier 1: Capacitor Plugin Hooks](#tier-1-capacitor-plugin-hooks)
- [Tier 2: Custom Scripts](#tier-2-custom-scripts)
- [Tier 3: Migration Blockers](#tier-3-migration-blockers)
- [Common Hook Types and Strategies](#common-hook-types-and-strategies)
- [Hook Analysis Workflow](#hook-analysis-workflow)
- [Analysis Output Template](#analysis-output-template)
- [Migration Checklist](#migration-checklist)

---

## Three-Tiered Approach

When analyzing a Cordova plugin with hooks, classify each hook into one of three tiers to determine the best migration path:

### Hybrid Plugin Detection (Run This First)

Before classifying hooks, open `package.json`. If you find any of these
script keys, the plugin is **hybrid**, it already supports Capacitor
alongside Cordova:

```json
{
  "scripts": {
    "capacitor:update:after": "node hooks/installRepo.js",
    "capacitor:sync:after": "node hooks/copyPreferences.js"
  }
}
```

Hybrid hook keys to look for:

- `capacitor:sync:before`, `capacitor:sync:after`
- `capacitor:copy:before`, `capacitor:copy:after`
- `capacitor:update:before`, `capacitor:update:after`

When a plugin is hybrid:

1. Record each existing `capacitor:*` script as a Tier 1 hook with status
   `already_converted`.
2. Read each referenced script. Capacitor hook scripts typically use
   `process.env.CAPACITOR_PLATFORM_NAME` and `process.env.CAPACITOR_ROOT_DIR`
   to locate the host app's native projects.
3. For each `<hook>` element in `plugin.xml`, check whether the existing
   Capacitor script already covers it. If so, mark the Cordova hook
   `superseded_by: <capacitor script>` in your notes. If not, classify it
   normally below.
4. Ask the user before rewriting an existing Capacitor script. The official
   Cordova plugin team may have already done the work; do not re-derive it.

Example handoff fragment for a hybrid plugin:

```yaml
migration:
  hooks:
    tier_1:
      - name: capacitorCopyPreferences
        src: hooks/capacitorCopyPreferences.js
        type: capacitor:sync:after
        purpose: Copy Apple Pay / Google Pay preferences from JSON config into native projects
        status: already_converted
      - name: insertAzureRepository
        src: hooks/insert_azure_repository.js
        type: capacitor:update:after
        purpose: Add Azure DevOps Maven repository to root build.gradle
        status: already_converted
    tier_2: []
    tier_3: []
```

### Decision guide: `<preference>`-driven plist / manifest mutations

A common Cordova pattern: `<preference name="API_KEY" default="...">`
combined with `<config-file target="*-Info.plist">` (or
`AndroidManifest.xml`) entries that substitute the preference into the
host app's native config at install time. The migrator routes these
based on **who supplies the value** and **what kind of mutation** it is:

| Cordova pattern | Capacitor destination | Why |
| --- | --- | --- |
| `<preference>` + `<config-file>` with **same value for every consumer** (e.g., a fixed usage description string, an enabled-by-default capability) | **Plugin's own AndroidManifest / podspec / Info.plist contribution** | Static, plugin-owned. Manifest merger / Capacitor sync handles it. |
| `<preference>` + `<config-file>` with **consumer-supplied value** that the plugin reads at runtime (API keys, merchant IDs, gateway IDs) | **Runtime config JSON file** consumed by a Tier 1 `capacitor:sync:after` script | Keeps per-consumer values out of the native projects entirely; reuse any existing hybrid script from the Cordova plugin. |
| `<preference>` + `<config-file>` with **consumer-supplied value** that must land in a static plist key the OS reads (e.g., Apple Pay merchant entitlement) | **Host app's native configuration** | Apple / Google require the static entry. For ODC consumers this happens automatically in Phase 11a of the migrator's ODC flow: `build-actions-generator` emits the entry into `build-actions/`, and the migrator tracks which items were covered so the generator skips them in Phase 11b. See `using-plugin-generator.md` "ODC Path" for the full sequence. For npm-only consumers, document a manual setup snippet in `MIGRATION.md`. |
| `<preference>` that pins a build-time version (`ANDROIDX_CORE_VERSION`) referenced inside the plugin's own `build.gradle` / `.podspec` | **Plugin's own gradle / podspec**, pin the resolved version literally | Build-time only; consumer never sees it. |
| Cordova hook **removes** a preference from a plist file after a previous step added it | **Runtime config JSON file**, not Build Actions | Build Actions does not have an operation to remove plist properties, only set / merge. If you can't restructure to avoid the remove step, fall back to a `capacitor:sync:after` script. |

The migrator does not emit Build Actions configuration itself. When a
value genuinely needs to land on the host app's static config, surface
it under `migration.notes` with the exact target key and value so the
reviewer (or a downstream skill) can apply it. Default routing should
prefer the runtime-config JSON pattern wherever possible, since it
avoids per-consumer Build Actions forks and works identically on ODC
and npm-only deployments.

### Tier 1: Capacitor Plugin Hooks (Preferred) ✅

**When to Use:**
- Hook modifies configuration files after sync
- Hook copies resources to native projects
- Hook runs build preparation tasks
- Hook behavior fits Capacitor's sync/copy/update lifecycle

**Available Capacitor Plugin Hooks (npm scripts in plugin `package.json`):**
- `capacitor:sync:before` / `capacitor:sync:after`, wraps `npx cap sync`
- `capacitor:copy:before` / `capacitor:copy:after`, wraps `npx cap copy`
- `capacitor:update:before` / `capacitor:update:after`, wraps `npx cap update`
- `capacitor:android:add:before` / `capacitor:android:add:after`
- `capacitor:ios:add:before` / `capacitor:ios:add:after`

(These are npm scripts declared in the plugin's `package.json`, not in
the host app's `capacitor.config.json`. The Capacitor CLI discovers them
automatically when it runs `cap sync` / `cap copy` / `cap update`.)

**Example Conversion:**
```xml
<!-- Cordova hook that modifies files after prepare -->
<hook type="after_prepare" src="scripts/modifyConfig.js" />
```

**Capacitor Equivalent (plugin's `package.json`):**
```json
{
  "scripts": {
    "capacitor:sync:after": "node scripts/modifyConfig.js"
  }
}
```

### Hook Script Rewriting, Cordova `context` → Capacitor `process.env.*`

The hook lifecycle hook-up is half the work; the **script content** also has
to change. Cordova hook scripts receive a `context` object as their first
argument:

```js
// Cordova hook script
module.exports = function (context) {
    const opts = context.opts;
    const cordovaRoot = opts.projectRoot;
    const platform = opts.cordova.platforms[0];        // 'ios' or 'android'
    const pluginInfo = opts.plugin.pluginInfo;
    const platformDir = path.join(cordovaRoot, 'platforms', platform);
    // ...
};
```

Capacitor's plugin hooks (npm scripts under `scripts.capacitor:*:*`) run
as ordinary npm scripts with no argument. Context comes through environment
variables exported by the Capacitor CLI:

```js
// Capacitor hook script (equivalent)
const projectRoot = process.env.CAPACITOR_ROOT_DIR;     // host app root
const platform = process.env.CAPACITOR_PLATFORM_NAME;   // 'ios' | 'android'
const pluginDir = process.env.CAPACITOR_PLUGIN_DIR;     // when set, path of the plugin module
const platformDir = path.join(projectRoot, platform === 'ios' ? 'ios/App' : 'android');
```

Translation rules when rewriting a hook script:

| Cordova `context.opts.*` | Capacitor equivalent |
| --- | --- |
| `opts.projectRoot` | `process.env.CAPACITOR_ROOT_DIR` |
| `opts.cordova.platforms[]` | `process.env.CAPACITOR_PLATFORM_NAME` (one platform per invocation) |
| `opts.plugin.pluginInfo` | Read the plugin's own `package.json` directly (`require('./package.json')`) |
| `path.join(opts.projectRoot, 'platforms/ios')` | `path.join(process.env.CAPACITOR_ROOT_DIR, 'ios/App')` |
| `path.join(opts.projectRoot, 'platforms/android')` | `path.join(process.env.CAPACITOR_ROOT_DIR, 'android')` |
| `cordovaCommon`, `cordova-common` modules | Drop the dependency, Capacitor scripts use plain `fs` / `path`. |

Hybrid plugins that already ship a `capacitor:sync:after` script use
this pattern: the script reads `CAPACITOR_ROOT_DIR` and
`CAPACITOR_PLATFORM_NAME` directly, with no `cordova-common` dependency
and no `context` argument. If the Cordova plugin you're migrating
already has one of those scripts, read it first; it's the working
template for whatever rewrite the other `<hook>` entries need.

Rewriting safety:

- If the script invokes Cordova-only CLI commands (`cordova-lib`,
  `cordova prepare`, plugin.xml mutation), it cannot be rewritten, that's
  a **Tier 3 blocker**, not Tier 1.
- Path swaps like `platforms/ios → ios/App` are exact; Capacitor sync
  copies into `<host>/ios/App` and `<host>/android` consistently.
- The Capacitor CLI invokes the script once per platform, so don't loop
  over platforms internally, branch on `process.env.CAPACITOR_PLATFORM_NAME`.

### Tier 2: Custom Scripts (Fallback) ⚠️

**When to Use:**
- Hook prints setup instructions, version notes, or links the consumer
  should see right after install (the most common real-world case).
- Hook performs a one-time task **scoped to the plugin package itself**:
  generating files inside `node_modules`, validating peer dependencies,
  caching a fetched schema, etc.
- Hook can be converted to an npm lifecycle script (`postinstall`,
  `preuninstall`) that runs against the plugin package, not the host app.

**Do NOT use Tier 2 for:**
- Installing CocoaPods (`pod install`). That's a consumer-side step, run
  against the host app's `ios/App/Podfile`. Capacitor 8 defaults to SPM,
  so many consumers won't run `pod install` at all.
- Running `npx cap sync` from the plugin's `postinstall`. Sync runs
  against the host app on demand; the plugin should never trigger it.
- Mutating the host app's native projects in any way. The consumer owns
  those files.
- Network downloads that the consumer's CI may block. If the asset is
  required at runtime, bundle it in the npm package or fetch it lazily
  from the runtime code.

**npm Lifecycle Script Approach (plugin-side only):**

```xml
<!-- Cordova hook that printed setup instructions after install -->
<hook type="after_plugin_install" src="scripts/printSetupInstructions.js" />
```

**Capacitor Equivalent:**
```json
// package.json (in the plugin)
{
  "scripts": {
    "postinstall": "node scripts/printSetupInstructions.js"
  }
}
```

**Manual Script Approach:**

For one-time setup that users must run manually:

```xml
<!-- Cordova hook that configures native project settings -->
<hook type="after_plugin_install" src="scripts/setupNativeProject.js" />
```

**Capacitor Equivalent:**
```markdown
## Installation

After installing this plugin, run the following setup script:

\`\`\`bash
npm install @company/my-plugin
node node_modules/@company/my-plugin/scripts/setupNativeProject.js
npx cap sync
\`\`\`

This script configures native project settings required for the plugin to function.
```

### Tier 3: Migration Blocker (Last Resort) ❌

**Indicators of a Migration Blocker:**
- Hook performs complex Cordova-specific operations
- Hook deeply integrates with Cordova CLI internals
- Hook modifies plugin.xml or config.xml at runtime
- Hook requires user interaction during build (not supported)
- Hook behavior is critical but cannot be automated in Capacitor

**Example Migration Blocker:**
```xml
<!-- Hook that dynamically modifies plugin.xml based on user input -->
<hook type="before_plugin_install" src="scripts/interactiveSetup.js" />
```

**Why It's a Blocker:**
- Capacitor does not support interactive hooks during installation
- plugin.xml does not exist in Capacitor (no equivalent to modify)
- User input during npm install is not supported in Capacitor workflow

**Potential Workarounds:**
1. **Runtime configuration**: Read config from capacitor.config.json
   ```json
   {
     "plugins": {
       "MyPlugin": {
         "apiKey": "user-provided-key"
       }
     }
   }
   ```

2. **Environment variables**: Use `.env` file or environment variables
   ```typescript
   const apiKey = process.env.MY_PLUGIN_API_KEY;
   ```

3. **Separate setup CLI**: Create a standalone setup tool
   ```bash
   npm install @company/my-plugin
   npx @company/my-plugin-setup
   npx cap sync
   ```

4. **Manual configuration steps**: Document in README

---

## Common Hook Types and Strategies

| Cordova Hook Type | Purpose | Capacitor Equivalent | Migration Tier |
|-------------------|---------|---------------------|----------------|
| `before_plugin_install` | Pre-install validation | ❌ Not supported | **Tier 2/3**: Document prerequisites or flag as blocker |
| `after_plugin_install` | Post-install setup | ✅ npm `postinstall` | **Tier 2**: Use `postinstall` script in package.json |
| `before_prepare` | Pre-build preparation | ✅ `capacitor:sync:before` | **Tier 1**: Use Capacitor sync hook |
| `after_prepare` | Post-build modifications | ✅ `capacitor:sync:after` | **Tier 1**: Use Capacitor sync hook |
| `before_build` | Pre-compilation tasks | ⚠️ Platform-specific | **Tier 2**: Xcode build phase / Gradle task |
| `after_build` | Post-compilation tasks | ⚠️ Platform-specific | **Tier 2**: Xcode build phase / Gradle task |
| `before_plugin_uninstall` | Cleanup before removal | ✅ npm `preuninstall` | **Tier 2**: Use `preuninstall` script |

---

## Hook Analysis Workflow

When analyzing a plugin with hooks, follow these steps:

### 1. Identify All Hooks
```bash
grep -n "<hook" plugin.xml
```

### 2. Read Hook Scripts
Examine each hook script to understand its purpose:
```javascript
// Example: Read scripts/afterInstall.js
// Understand: What files does it modify? What does it install?
```

### 3. Categorize by Tier
- Can it use Capacitor hooks? → **Tier 1**
- Can it use npm scripts or manual steps? → **Tier 2**
- Is it fundamentally incompatible? → **Tier 3 (blocker)**

### 4. Document in Analysis
Use the template below to document findings.

---

## Analysis Output Template

When hooks are detected, include this in the migration analysis:

```markdown
## 🔧 Cordova Hooks Migration Analysis

**Hooks Detected:** [Number] hook(s) found in plugin.xml

### Hook 1: Resource Copier (after_prepare)
**Location:** plugin.xml:42
**Script:** scripts/copyResources.js
**Purpose:** Copies custom fonts and assets to native projects

**Migration Strategy:** ✅ **Tier 1 - Capacitor Hook**

**Recommended Approach:**
\`\`\`json
// Document in README: Users should add to capacitor.config.json
{
  "hooks": {
    "capacitor:sync:after": "node node_modules/@company/plugin/scripts/copyResources.js"
  }
}
\`\`\`

**Implementation Notes:**
- Script needs minor modifications to support Capacitor project structure
- Change paths from `platforms/ios` to `ios/App`
- Change paths from `platforms/android` to `android/app`

---

### Hook 2: Setup Instructions Banner (after_plugin_install)
**Location:** plugin.xml:45
**Script:** scripts/printSetupInstructions.js
**Purpose:** Prints the Info.plist privacy strings, AndroidManifest entries,
and any capability toggles the consumer must add to their host app, so the
steps surface immediately after install instead of being buried in the
README. The most common real `after_plugin_install` pattern in the
Cordova ecosystem.

**Migration Strategy:** ⚠️ **Tier 2 - npm `postinstall`**

**Recommended Approach:**
\`\`\`json
// Add to plugin's package.json
{
  "scripts": {
    "postinstall": "node scripts/printSetupInstructions.js"
  }
}
\`\`\`

**Implementation Notes:**
- Runs once per plugin install, against the plugin package itself.
  Prints to stdout, no side effects on the host app.
- Do **not** chain `pod install` or `npx cap sync` here. CocoaPods is a
  consumer-side step (against the host app's `Podfile`), and Capacitor 8
  defaults to SPM anyway. `cap sync` runs on the host app, not the plugin.
- Skip the banner if README + MIGRATION.md already cover the same setup
  steps. Duplicated instructions go stale.

---

### Hook 3: Interactive Configuration (before_plugin_install)
**Location:** plugin.xml:38
**Script:** scripts/interactiveSetup.js
**Purpose:** Prompts user for API keys and writes to plugin.xml

**Migration Strategy:** ❌ **Tier 3 - Migration Blocker**

**Issue:**
This hook requires user interaction during installation and modifies plugin.xml,
neither of which are supported in Capacitor's architecture.

**Recommended Workarounds:**
1. **Runtime configuration**: Read API keys from capacitor.config.json
   \`\`\`json
   {
     "plugins": {
       "MyPlugin": {
         "apiKey": "user-provided-key"
       }
     }
   }
   \`\`\`

2. **Environment variables**: Use `.env` file or environment variables
   \`\`\`typescript
   const apiKey = process.env.MY_PLUGIN_API_KEY;
   \`\`\`

3. **Separate setup CLI**: Create a standalone setup tool
   \`\`\`bash
   npm install @company/my-plugin
   npx @company/my-plugin-setup
   npx cap sync
   \`\`\`

**Impact:**
This is a **significant architectural change** that requires redesigning
how the plugin is configured. Consider this a **potential migration blocker**
pending user input on acceptable workarounds.

---

## 📋 Hooks Migration Summary

**Total Hooks:** [Number]
- ✅ **Tier 1 (Capacitor Hooks):** [Number] - Can be converted directly
- ⚠️ **Tier 2 (Custom Scripts):** [Number] - Requires npm scripts or manual steps
- ❌ **Tier 3 (Blockers):** [Number] - Potential migration blockers

**Overall Assessment:**
[Summary of whether hooks are a significant concern for migration]

**Recommended Next Steps:**
1. [Prioritized list of actions needed for hook migration]
2. [Any decisions needed from the user]
3. [Any architectural changes required]
```

---

## Migration Checklist

When analyzing hooks, verify:

- [ ] All hooks identified from plugin.xml
- [ ] Hook scripts analyzed for functionality
- [ ] Tier classification assigned to each hook
- [ ] **Tier 1 (Capacitor hooks)**: Migration path documented
- [ ] **Tier 2 (Custom scripts)**: npm scripts or manual steps documented
- [ ] **Tier 3 (Blockers)**: Workarounds proposed and blocker severity assessed
- [ ] User action required: Clearly documented in analysis summary
- [ ] Breaking changes: Noted if hook behavior cannot be fully replicated

---

## When to Flag as Migration Blocker

Include hooks in the **⚠️ Migration Blockers** section when:

1. ❌ Hook performs interactive operations (user input during install)
2. ❌ Hook modifies Cordova-specific files (plugin.xml, config.xml)
3. ❌ Hook depends on Cordova CLI internals not present in Capacitor
4. ❌ Hook behavior is critical but cannot be automated
5. ❌ Workarounds would significantly change plugin behavior or user experience

**Example Blocker Warning:**
```markdown
## ⚠️ Migration Blockers Detected

### Critical: Interactive Installation Hook
**Impact:** High - Affects initial plugin setup

The plugin uses a `before_plugin_install` hook that interactively
prompts for configuration. This cannot be converted to Capacitor.

**Workarounds:**
1. Move configuration to capacitor.config.json (breaking change)
2. Create separate setup tool (extra step for users)
3. Use environment variables (requires documentation update)

**Recommendation:**
Consider this a **potential migration blocker**. Recommend discussing
with the user which workaround is acceptable before proceeding with
migration.
```
