# Testing and Workflow

Generated plugins must be verified as far as the local environment allows.
Report skipped checks clearly.

## Core Commands

```bash
npm install
npm run build
npm run docgen
npm run verify:web
npm run verify:ios
npm run verify:android
npm run verify
npm run lint
npm run fmt
```

Use platform-specific verify commands when the full native toolchain is not
available.

## Local Linking

To test the generated plugin from a sample app:

```bash
cd <plugin-root>
npm install
npm run build

cd <sample-app>
npm install
npm install ../<plugin-root>
npx cap sync
```

## Capacitor CLI Workflow

Use these commands intentionally:

| Command | When to use |
| --- | --- |
| `npx cap add ios` / `npx cap add android` | Add a native platform to a sample app that does not already have it. |
| `npx cap sync` | After installing the local plugin, changing native plugin code, changing dependencies, editing Capacitor config, or rebuilding web assets for native testing. |
| `npx cap copy` | After web-only sample app changes when native dependencies/config did not change. |
| `npx cap open ios` / `npx cap open android` | Open the native IDE for simulator/device selection, signing, Gradle sync, or manual platform inspection. |
| `npx cap run ios` / `npx cap run android` | Build and run the sample app on a simulator, emulator, or connected device. |

If generated native code, plugin metadata, permissions, dependencies, or config
changed, prefer `npx cap sync` over `npx cap copy`.

For web-only sample validation:

```bash
npm start
```

For native validation:

```bash
npx cap run ios
npx cap run android
```

## Review Checklist

- `src/definitions.ts` contains the complete contract with JSDoc and `@since`.
- `src/index.ts`, iOS `jsName`, and Android `@CapacitorPlugin(name)` match.
- `src/web.ts` uses dynamic registration, feature detection, and proper errors.
- iOS bridge methods are `@objc` and listed in `pluginMethods`.
- Android bridge methods are public and annotated with `@PluginMethod()`.
- Events use identical strings across all platforms.
- Permissions are explicit in API, native code, and generated docs.
- Dependencies are declared in the platform package files and documented.
- Sample app exercises every method and listener.
- README API docs come from `npm run docgen`.

## Hooks

If generated output needs package lifecycle hooks, prefer npm scripts and keep
them explicit in `package.json`. Do not generate Cordova hook patterns. If the
structured migration input includes tier 3 hooks, stop and ask for migration
analysis to resolve them before generation.

## Manual Validation Notes

Some plugin categories require real devices, credentials, or store-facing
configuration. Mark those as manual review items rather than claiming full
runtime correctness.
