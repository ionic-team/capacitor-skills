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

## Type Resolution

Module augmentation only resolves at build time when the augmented module is
actually installed. When the generated TypeScript declares
`declare module '<name>'` or uses a `/// <reference types="<name>" />`
triple-slash directive:

- Add the augmented package to `devDependencies` in `package.json`. For
  Capacitor plugin configuration types this is `@capacitor/cli`.
- For triple-slash references, ensure the same package is reachable via
  `tsconfig.json` `compilerOptions.types` or `typeRoots`. Most templates do
  not need an explicit `types` array because TypeScript discovers
  `node_modules/@types` automatically — the install is what matters.
- TypeScript will fail with `Cannot find type definition file for '<name>'`
  or `Invalid module name in augmentation, module '<name>' cannot be found`
  when the augmented module is not installed at build time.

This rule applies to any module augmentation, not just `@capacitor/cli`.

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
