# Design Patterns

Use Capacitor's Bridge pattern by default. Add a Facade-style coordinator and
smaller services only when the plugin is complex enough to need multiple
cooperating native components.

## Bridge Pattern: Default

The bridge pattern separates the Capacitor bridge from native business logic.
Treat the plugin bridge class as a controller: it parses calls, gates
permissions, delegates work, maps results, and emits events. It should not grow
into the whole implementation.

```
JavaScript API
  -> Capacitor plugin bridge class
    -> Native implementation class
      -> Platform APIs
```

Use this for simple and medium plugins:

- Small or moderate public API surfaces.
- Platform-specific work that fits behind clear method boundaries.
- Plugins where the bridge class can translate calls, enforce permissions, and
  delegate native work without coordinating many subsystems.

Benefits:

- Keeps `CAPPlugin` / `Plugin` classes thin.
- Makes native logic easier to unit test.
- Reduces mismatch between TypeScript, iOS, Android, and web implementations.

## Code Organization

Split implementation by responsibility rather than by convenience:

- `<PluginName>Plugin`: Capacitor bridge/controller only.
- `<PluginName>` or `<Feature>Manager`: platform API calls and native behavior.
- `<PermissionManager>`: runtime permissions or special settings access.
- `<Config>`: plugin configuration defaults and parsing.
- `<Mapper>` or small helpers: platform enum/string/result conversion.

Extract reusable parsing, validation, clamping, enum mapping, and result-building
helpers. Do not leave permission handling, platform API calls, serialization,
and sample-only logic in one large bridge method.

## Facade Pattern: Complex Subsystems

Use a Facade when a plugin coordinates several native subsystems. `Facade` is
the design pattern name; generated class names may use `Facade`, `Coordinator`,
or `Manager` when that better matches the platform or domain.

- Complex lifecycle, permission, foreground/background, external SDK, or
  long-lived event flows.
- Plugins that need multiple managers, delegates, receivers, activities, or
  lifecycle hooks.
- Plugins where a single implementation class would become a large coordinator.

The Capacitor plugin class should still stay thin. It should delegate to a
coordinator that owns subsystem orchestration and delegates focused work to
services such as permission, lifecycle, event, dependency, and data managers.

## Event Parity

Every event name is a contract string. Keep the exact same value in:

- `src/definitions.ts` listener overload.
- `src/web.ts` `notifyListeners()`.
- iOS `notifyListeners(_:data:)`.
- Android `notifyListeners(name, data)`.
- Sample app listener registration.

Do not translate event names per platform.

## Event Dispatch Locality

Capacitor's `notifyListeners(...)` is intentionally scoped to the plugin class
on both platforms — `protected` on Android and reached through `self` on iOS.
Generated code must respect this:

- Implementation classes, managers, services, broadcast receivers, and
  observers must not call `plugin.notifyListeners(...)` through a captured
  plugin reference. The Android compiler rejects it; iOS allows it but it is
  fragile and breaks when the plugin is not yet loaded.
- Either return event data to the plugin class and dispatch there, or expose a
  `public` wrapper method on the plugin class that calls `notifyListeners(...)`
  internally.
- Background contexts that may run before the plugin is loaded (FCM service,
  APNs receipt, deep-link intent, broadcast receiver) must dispatch through a
  static accessor on the plugin class, not through a captured plugin instance,
  because the plugin may not exist yet.

Treat this as a non-negotiable rule. Violations surface as access-modifier
compile errors on Android and silent no-ops or crashes on iOS.

## Bridge Performance

Each call across the JavaScript ↔ native bridge has serialization and
context-switch overhead. Generated APIs should default to shapes that
minimize bridge traffic:

- **Prefer batch operations over loops.** Expose a batch method when the
  caller is likely to invoke the same operation many times in succession.

  ```typescript
  // 100 bridge crossings.
  for (const id of ids) await Plugin.processItem({ id });

  // 1 bridge crossing.
  await Plugin.processBatch({ ids });
  ```

- **Pass file URIs/paths instead of base64 for large binary payloads.**
  Photos, audio recordings, and downloaded files should round-trip as
  filesystem paths or `content://` URIs. Base64 inflates payload size by
  ~33% and forces a full UTF-16 traversal in V8/JSC.

  ```typescript
  // Avoid for non-trivial sizes.
  await Plugin.processImage({ data: base64EncodedMegabytes });

  // Preferred.
  await Plugin.processImage({ uri: 'file:///path/to/image.jpg' });
  ```

- **Use events for streams, not polling.** When the native side produces
  data continuously (sensors, location, download progress), expose
  `addListener(...)` and `notifyListeners(...)`; do not require the caller
  to poll a `getCurrent()` method on a timer.

These are defaults, not hard rules. Small payloads, one-shot calls, and
debug-only methods can ignore them.

## Security

Two cross-platform rules that are easy to miss in generated code:

- **Validate at the boundary.** The bridge is a trust boundary between app
  code and the native runtime. Before passing user-supplied strings to
  privileged APIs (file paths, URLs, intent extras, shell-like inputs),
  validate the shape on the side that constructs the call:

  ```typescript
  async openLink(options: { url: string }): Promise<void> {
    if (!/^https?:\/\//.test(options.url)) {
      const err = new Error('http(s) URL required');
      (err as Error & { code: string }).code = 'INVALID_PARAMETER';
      throw err;
    }
    // pass to native
  }
  ```

  Apply the same rule to file paths (reject absolute paths or `..` traversal
  unless intentional) and to any input that becomes a system intent extra.

- **Do not log secrets.** Tokens, passwords, biometric outputs, API keys,
  and credentials must not appear in `print()` / `Log.d()` / `console.log()`
  even at debug level. Generated code should log the *attempt*, not the
  payload:

  ```swift
  // ❌ leaks secret to device console
  print("Authenticating with token: \(token)")

  // ✅ visibility without exposure
  Logger.info("Authentication attempt")
  ```

  Generated `Logger`/`Log.d`/`console.log` calls in the candidate plugin
  must be reviewed before publish — see the Candidate Output Rule below.

## Candidate Output Rule

Generated output is a reviewable starting point, not production-ready code.
Flag native areas that require credentials, entitlement setup, real-device
testing, app store policy review, or manual SDK configuration.
