# Web Guide

The web implementation should either wrap an actual Web API or clearly report
that the capability is unavailable or unimplemented.

## Pattern

```typescript
import { WebPlugin } from '@capacitor/core';

import type {
  ExamplePlugin,
  GetSignalOptions,
  GetSignalResult,
} from './definitions';

export class ExampleWeb extends WebPlugin implements ExamplePlugin {
  async getSignal(options: GetSignalOptions): Promise<GetSignalResult> {
    if (!globalThis.navigator) {
      throw this.unavailable('Navigator is not available in this browser.');
    }

    if (!('connection' in globalThis.navigator)) {
      throw this.unimplemented('The Network Information API has no supported web equivalent here.');
    }

    return {
      level: options.source === 'wifi' ? 100 : 50,
    };
  }
}
```

## `unavailable()` vs `unimplemented()`

| Use | Meaning |
| --- | --- |
| `this.unavailable(message)` | A relevant Web API exists, but this browser/platform/session cannot use it. |
| `this.unimplemented(message)` | There is no meaningful web implementation for this native feature. |

Feature-detect before touching optional browser APIs. Avoid user-agent checks
unless the API itself gives no reliable capability signal.

If `src/definitions.ts` includes `checkPermissions()` or
`requestPermissions()`, implement both in `src/web.ts`. Use the Web Permissions
API only after feature detection; throw `unavailable()` when the browser lacks
the needed API and `unimplemented()` when web cannot request that permission.

## Events

If the plugin emits events:

```typescript
this.notifyListeners('signalChange', { level: 72 });
```

The event string must exactly match the TypeScript listener overload and native
platform `notifyListeners()` calls.

## Dynamic Import

Register web through `src/index.ts`:

```typescript
const Example = registerPlugin<ExamplePlugin>('Example', {
  web: () => import('./web').then((m) => new m.ExampleWeb()),
});
```

This keeps the web implementation lazy-loaded and matches Capacitor generator
conventions.
