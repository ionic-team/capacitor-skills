# Plugin Configuration

Use Capacitor config for values that app developers should control without code
changes. Configuration keys live under `plugins.<PluginJSName>`.

## TypeScript Shape

Document configuration in the generated README and, when useful, mirror it in a
TypeScript interface by extending `PluginsConfig` from `@capacitor/cli`:

```typescript
/// <reference types="@capacitor/cli" />

declare module '@capacitor/cli' {
  export interface PluginsConfig {
    Example?: {
      /**
       * Enables verbose native logging.
       *
       * @default false
       * @since 1.0.0
       */
      debug?: boolean;
    };
  }
}
```

## Capacitor Config Example

```typescript
import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  plugins: {
    Example: {
      debug: true,
    },
  },
};

export default config;
```

## iOS

Read values from the plugin config using the same key names:

```swift
let debug = getConfig().getBoolean("debug", false)
```

## Android

Read values from the plugin config using the same key names:

```java
boolean debug = getConfig().getBoolean("debug", false);
```

## Rules

- Keep config names stable and documented.
- Do not use config for per-call options; use method options interfaces.
- Keep defaults identical across web, iOS, and Android.
- If a config key affects only one platform, document platform availability.
