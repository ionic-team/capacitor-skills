# Designing the TypeScript API

The TypeScript contract drives every generated platform. Design
`src/definitions.ts` before implementing web, iOS, or Android.

## Contract Rules

- Methods return `Promise<T>` or `Promise<void>`.
- A method has at most one parameter named `options`.
- Name method options `<MethodName>Options`.
- Name method results `<MethodName>Result`.
- Define separate interfaces for options, results, and event payloads.
- Use string union types instead of TypeScript enums.
- Use `undefined` rather than `null` for absent optional values.
- Import type-only symbols with `import type` and avoid unused imports.
- Use stable cross-platform units and ISO 8601 strings for dates.
- Add JSDoc and `@since` to every public interface, method, property, type, and
  listener overload.
- If any method needs runtime permission, special settings access, or manual
  native setup, add `checkPermissions()` and `requestPermissions()` to the API
  unless Capacitor provides a more specific established pattern.
- If the same user-facing capability has both local and system-wide variants,
  model them explicitly instead of hiding platform differences.

## Method Naming

Use action verbs that disambiguate intent. The verb dictates the method's
contract — readers should be able to predict the return shape from the name
alone.

| Verb        | Use for                                  | Example                                           |
| ---         | ---                                      | ---                                               |
| `get`       | Retrieve current state, no side effects  | `getStatus()`, `getCurrentPosition()`             |
| `check`     | Test a condition, no prompt              | `checkPermissions()`, `isAvailable()`             |
| `request`   | Ask the user or system for something     | `requestPermissions()`                            |
| `start`/`stop` | Begin or end a continuous operation   | `startMonitoring()`, `stopMonitoring()`           |
| `create`/`delete` | Manage a resource lifecycle         | `createChannel()`, `deleteFile()`                 |
| `update`    | Mutate existing state                    | `updateSettings()`                                |
| `open`/`close` | Show or dismiss platform UI           | `openSettings()`, `closeDialog()`                 |
| `add`/`remove` | Manage a collection                   | `addListener()`, `removeAllListeners()`           |

Avoid bare nouns (`status()`, `permissions()`) — readers cannot tell whether
they read or write.

## Return-Shape Extensibility

Wrap primitive returns in an object so the API can grow without breaking
consumers. Adding a field to an object is non-breaking; changing a primitive
return type is breaking.

```typescript
// Brittle — cannot add fields later without breaking callers.
async isAvailable(): Promise<boolean>;
async listFiles(): Promise<FileInfo[]>;

// Extensible — new fields can be added in a minor version.
async isAvailable(): Promise<{ available: boolean; reason?: string }>;
async listFiles(): Promise<{ files: FileInfo[]; truncated?: boolean }>;
```

Apply the same shape rule to error/availability surfaces:

```typescript
export interface FeatureAvailability {
  available: boolean;
  /** Why the feature is unavailable on this device/session. */
  reason?: string;
}
```

## Platform-Specific Options

When iOS and Android need substantively different inputs for the same logical
operation, surface the divergence with namespaced sub-objects rather than
flattening platform-specific keys into the top level:

```typescript
export interface NotificationOptions {
  /** Common across platforms. */
  title: string;
  body: string;

  /** iOS-only fields. */
  ios?: {
    sound?: string;
    badge?: number;
    threadId?: string;
  };

  /** Android-only fields. */
  android?: {
    channelId: string;
    smallIcon?: string;
    priority?: 'high' | 'low';
  };
}
```

Document which keys are platform-specific in JSDoc. Platform-specific options
should be optional from the contract's perspective; the native side falls back
to sensible defaults if the consumer omits them.

## When Mirroring an Existing API

If the requested plugin mirrors an existing public API — a Capacitor
core/community plugin, a Capawesome plugin, an internal library, or a
documented JavaScript API the user is replacing — look up the actual source
`definitions.ts` (or equivalent) before generating. Match the wire-format
string literal values exactly. Do not derive them from human-friendly names or
TypeScript enum key names.

A common failure mode: a known API exposes a TypeScript enum like
`enum Style { Heavy = 'HEAVY', Medium = 'MEDIUM', Light = 'LIGHT' }`. If the
contract is generated from the human description ("style options Heavy,
Medium, Light") instead of the source, the generator may produce
`'Heavy' | 'Medium' | 'Light'` as the union — which is not the wire format and
will not interoperate with apps already using the official plugin.

The structured YAML mode pins these values in `api.types[].values` so the
generator does not need to guess. Conversational mode must consult the source
when a target API exists; otherwise, document the chosen wire format
explicitly so reviewers can see what was decided.

### Native Dependency Detection

Mirroring an existing API means matching its architecture too. Before
generating native code, inspect the official plugin's dependency
declarations:

- **iOS** — read the `.podspec` for `s.dependency '<Library>'` and
  `Package.swift` for `dependencies: [.package(url: ...)]`.
- **Android** — read `android/build.gradle` for
  `implementation '<group>:<artifact>:...'` entries (excluding
  `:capacitor-android` itself).

If the official plugin depends on a native library that wraps the underlying
platform API, the candidate plugin **must declare the same dependency and
delegate to it** — do not reimplement from scratch. The skill's job is
wire-compatibility *and* architectural compatibility; reimplementing under
the same TypeScript surface produces a divergent fork that loses upstream
bug fixes, behavior parity, and platform-quirk handling.

When the SDK is wrapped, the bridge class becomes a thin adapter — see
`references/ios-guide.md` and `references/android-guide.md` for the SDK
adapter pattern.

When the official plugin's bridge code is available locally, **read its
actual SDK call sites and mirror them**. The official plugin is the
canonical example of how to call this SDK from a Capacitor bridge; do not
invent alternative API surfaces based on the SDK's name alone (e.g.,
inferring class names like `XCameraLib.takePhoto(request:completion:)` from
the package title). Match the official's import statements, type names,
delegate conformances, and method signatures exactly.

If the official source is not reachable and the SDK headers cannot be read,
the candidate must still compile. Generate a local protocol/interface stub
named `<SDKName>Bridge` with the operations the plugin needs, and inject a
placeholder implementation that rejects with `unimplemented()`. Mark every
call site with a `TODO(SDK): wire up <method> via <real SDK class>`
comment so a human reviewer can complete the integration. Never import
speculative type names that the agent has not verified exist.

## Versioning and Deprecation

Annotate evolution explicitly. Every public symbol already needs `@since`;
methods, types, or properties scheduled for removal also need `@deprecated`.

```typescript
interface ExamplePlugin {
  /**
   * @deprecated Use `getDataV2()` instead. Removed in v3.0.0.
   * @see getDataV2
   * @since 1.0.0
   */
  getData(): Promise<OldData>;

  /**
   * Improved data fetching with additional fields.
   *
   * @since 2.1.0
   * @requires iOS 14+, Android 11+
   */
  getDataV2(): Promise<NewData>;
}
```

Implementation rules:

- A deprecated method must still work — keep it forwarding to its
  replacement and log once at runtime so consumers see the migration
  notice in development:

  ```typescript
  async getData(): Promise<OldData> {
    console.warn('[ExamplePlugin] getData is deprecated; use getDataV2');
    return this.getDataV2() as unknown as OldData;
  }
  ```

- `@requires` documents minimum platform/OS versions. Pair with a runtime
  guard (`unavailable()` on the native side) so calls on older OS versions
  reject cleanly rather than crash at the API boundary.
- Bump the npm `version` field per semver: MAJOR removes deprecated APIs,
  MINOR adds new ones, PATCH fixes bugs without contract changes.

## Example

```typescript
import type { PermissionState, PluginListenerHandle } from '@capacitor/core';

/**
 * @since 1.0.0
 */
export interface ExamplePlugin {
  /**
   * Returns the current device signal level.
   *
   * @since 1.0.0
   */
  getSignal(options: GetSignalOptions): Promise<GetSignalResult>;

  /**
   * Listen for signal changes.
   *
   * @since 1.0.0
   */
  addListener(
    eventName: 'signalChange',
    listenerFunc: (event: SignalChangeEvent) => void,
  ): Promise<PluginListenerHandle>;

  /**
   * Remove all listeners for this plugin.
   *
   * @since 1.0.0
   */
  removeAllListeners(): Promise<void>;
}

/**
 * @since 1.0.0
 */
export interface GetSignalOptions {
  /**
   * Measurement source.
   *
   * @since 1.0.0
   */
  source: SignalSource;
}

/**
 * @since 1.0.0
 */
export interface GetSignalResult {
  /**
   * Signal level from 0 to 100.
   *
   * @since 1.0.0
   */
  level: number;
}

/**
 * @since 1.0.0
 */
export interface SignalChangeEvent {
  /**
   * Signal level from 0 to 100.
   *
   * @since 1.0.0
   */
  level: number;
}

/**
 * @since 1.0.0
 */
export type SignalSource = 'wifi' | 'cellular';
```

## Method Signature Mapping

| API behavior | TypeScript | iOS return type | Android annotation |
| --- | --- | --- | --- |
| Returns a value | `Promise<Result>` | `CAPPluginReturnPromise` | `@PluginMethod()` |
| Returns no value | `Promise<void>` | `CAPPluginReturnNone` | `@PluginMethod(returnType = PluginMethod.RETURN_NONE)` |
| Native callback/watch method | `Promise<CallbackID>` with a callback parameter | `CAPPluginReturnCallback` | `@PluginMethod(returnType = PluginMethod.RETURN_CALLBACK)` |

Use callback return types only for native streams or watchers that save and
reuse a `PluginCall`. Events should usually be modeled with `addListener()` and
`notifyListeners()`.

## Permission Shape

When permissions are needed, expose explicit permission methods and a typed
status object:

```typescript
/**
 * @since 1.0.0
 */
export interface PermissionStatus {
  /**
   * @since 1.0.0
   */
  example: PermissionState;
}
```

Import `PermissionState` from `@capacitor/core` unless the plugin needs custom
states. Use string unions for plugin-specific modes, even when a reference
plugin or native SDK uses numeric constants or TypeScript enums.

## Error Codes

Reject with a small, consistent vocabulary of code strings across web, iOS,
and Android so consumers can write unified error handling. Add new codes
only when callers genuinely need to branch on the cause; do not invent a
one-off code per call site.

| Code                  | When to use                                                                  |
| ---                   | ---                                                                          |
| `UNAVAILABLE`         | The feature is not supported on this platform/device/session.                |
| `PERMISSION_DENIED`   | The user denied a runtime permission (or it was permanently denied).         |
| `INVALID_PARAMETER`   | Arguments fail validation: missing, wrong type, or out of range.             |
| `OPERATION_FAILED`    | The native operation failed for a reason not covered above.                  |

Subtype `OPERATION_FAILED` only when callers need to branch on cause:
`NETWORK_ERROR`, `HARDWARE_ERROR`, `TIMEOUT`, `CANCELLED`. Keep the surface
small.

Native reject signatures take the message first and the code second:

```swift
// iOS
call.reject("Camera permission not granted", "PERMISSION_DENIED")
```

```java
// Android
call.reject("Camera permission not granted", "PERMISSION_DENIED");
```

```typescript
// Web — attach a `code` property so consumers see the same wire shape.
const error = new Error('Camera permission not granted');
(error as Error & { code: string }).code = 'PERMISSION_DENIED';
throw error;
```

Consumers then write the same handler regardless of platform:

```typescript
try {
  await MyPlugin.method();
} catch (e) {
  if ((e as { code?: string }).code === 'PERMISSION_DENIED') {
    // show rationale, offer settings link
  }
}
```

See `references/ios-guide.md` and `references/android-guide.md` for how to
centralize these as a Swift enum and a Java constants class so the codes do
not drift across methods.

## Registration

`src/index.ts` should register the plugin and lazily load the web implementation:

```typescript
import { registerPlugin } from '@capacitor/core';

import type { ExamplePlugin } from './definitions';

const Example = registerPlugin<ExamplePlugin>('Example', {
  web: () => import('./web').then((m) => new m.ExampleWeb()),
});

export * from './definitions';
export { Example };
```

## Common Anti-Patterns

Three contract shapes that look reasonable but consistently cause friction:

- **Stringly-typed dispatch**:

  ```typescript
  // Avoid: collapses every operation into one method, defeats type checking.
  doAction(action: string, data: unknown): Promise<unknown>;

  // Prefer specific methods with typed options/results.
  capturePhoto(options: CapturePhotoOptions): Promise<CapturePhotoResult>;
  recordVideo(options: RecordVideoOptions): Promise<RecordVideoResult>;
  ```

- **Mutating the caller's options object** in the implementation. The
  options object passed across the bridge belongs to the caller. Native
  code receives a JSON copy anyway, so any "mutation" only affects a local
  clone — surface that clearly by treating options as read-only inputs and
  returning new result objects.

- **Boolean parameters that change behavior**:

  ```typescript
  // Avoid: caller has to remember what `true` means at every call site.
  loadFile(path: string, sync: boolean): Promise<string>;

  // Prefer named modes or distinct methods.
  loadFile(options: { path: string; mode: 'sync' | 'async' }): Promise<string>;
  ```

These shapes show up most often when a contract is generated from a verbal
description that did not break operations into typed shapes. When in doubt,
err toward more specific methods with `<MethodName>Options` /
`<MethodName>Result` interfaces.
