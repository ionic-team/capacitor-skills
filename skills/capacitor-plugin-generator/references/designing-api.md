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
