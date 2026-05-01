# Android Guide

The Capacitor generator creates Java by default. Keep Java unless the user asks
for Kotlin or the scaffold is already converted. Keep the Capacitor plugin class
thin and delegate native work to an implementation class.

## Bridge Shape

```java
package com.example.plugin;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

@CapacitorPlugin(name = "Example")
public class ExamplePlugin extends Plugin {
    private final Example implementation = new Example();

    @PluginMethod()
    public void getSignal(PluginCall call) {
        String source = call.getString("source");
        if (source == null) {
            call.reject("source is required");
            return;
        }

        JSObject ret = new JSObject();
        ret.put("level", implementation.getSignal(source));
        call.resolve(ret);
    }
}
```

```java
package com.example.plugin;

public class Example {
    public int getSignal(String source) {
        return 100;
    }
}
```

## Rules

- `@CapacitorPlugin(name)` must match `registerPlugin()` and iOS `jsName`.
- Every callable method must be public and annotated with `@PluginMethod()`.
- Parse `PluginCall` values in the plugin bridge class.
- Keep platform logic in the implementation class or facade.
- Keep imports minimal; include only Android and Capacitor classes used by the file.
- Use `call.resolve()`, `call.reject()`, `call.unavailable()`, or
  `call.unimplemented()` consistently with TypeScript/web behavior.
- Use `notifyListeners("eventName", payload)` for events.
- Add `@Override public void load()` only for plugin startup wiring such as
  native observers, managers, or receivers.

## Plugin Errors as Constants

Centralize the standard error codes from `references/designing-api.md` so
the bridge does not pass raw strings around:

```java
public final class PluginErrors {
    public static final String UNAVAILABLE = "UNAVAILABLE";
    public static final String PERMISSION_DENIED = "PERMISSION_DENIED";
    public static final String INVALID_PARAMETER = "INVALID_PARAMETER";
    public static final String OPERATION_FAILED = "OPERATION_FAILED";

    private PluginErrors() {}
}

// Usage — message first, code second
call.reject("Camera permission not granted", PluginErrors.PERMISSION_DENIED);
```

This keeps the wire format consistent — typos cannot drift between methods —
and the constants match the iOS `PluginError` enum so consumers see the same
code regardless of platform.

## Permissions

If Android runtime permissions are needed:

```java
import android.Manifest;

import com.getcapacitor.Plugin;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.getcapacitor.annotation.Permission;

@CapacitorPlugin(
    name = "Example",
    permissions = {
        @Permission(
            alias = "notifications",
            strings = { Manifest.permission.POST_NOTIFICATIONS }
        )
    }
)
public class ExamplePlugin extends Plugin {
}
```

- Add `checkPermissions()` and `requestPermissions()` to the TypeScript API.
- For standard `@Permission` aliases, Capacitor's inherited permission methods
  are usable. Implement custom methods only when the plugin needs special
  settings access or custom status mapping.
- Map Android permission results to Capacitor states.
- Put install-time permissions in the plugin `AndroidManifest.xml`. Document
  runtime permissions that the app developer must add to the app manifest.
- For Android 13+ notification permission, handle `POST_NOTIFICATIONS`
  explicitly when generating notification-related plugins.

### Special Settings Access

Some Android capabilities use special settings access rather than normal
runtime permissions. Do not model these as ordinary `@Permission` prompts.

For these capabilities:

- Decide whether the requested behavior is app-local or system-wide.
- Prefer app-local APIs when they satisfy the requested behavior and document
  their scope.
- For system-wide behavior, add explicit `checkPermissions()` and
  `requestPermissions()` methods to the TypeScript API.
- Declare required manifest permissions or setup steps in generated docs.
- Check access with the capability-specific Android API before attempting the
  protected operation.
- Request access by opening the appropriate Android settings intent.
- Return `prompt` after opening settings when Android cannot synchronously
  report the user's decision.
- Re-check access when the app resumes or before the protected operation.
- Keep platform value conversions in a mapper/helper instead of inline bridge
  code.
- Reject protected operations with actionable messages when access is missing.

## Dependencies

- Add Gradle dependencies to `android/build.gradle`.
- Add Maven repositories only when the dependency is not available from the
  existing repository set.
- Document any required app-level Gradle, manifest, service, receiver, or
  Firebase configuration that cannot be safely generated in the plugin package.

## Opening App Settings After Permanent Denial

Once a user has denied a runtime permission and selected "Don't ask again",
Android will not re-prompt. The plugin can only deep-link to the system app
settings so the user can change the choice manually.

```java
@PluginMethod()
public void openSettings(PluginCall call) {
    Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
    intent.setData(Uri.fromParts("package", getContext().getPackageName(), null));
    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
    try {
        getContext().startActivity(intent);
        JSObject ret = new JSObject();
        ret.put("opened", true);
        call.resolve(ret);
    } catch (Exception e) {
        call.reject("Cannot open settings", e);
    }
}
```

Expose this as `openSettings()` on the plugin contract whenever the API has a
permission flow. The user-facing prompt for "permission denied" should offer
this as a recovery path.

## Do Not Shadow `Plugin` API Methods With Weaker Visibility

`com.getcapacitor.Plugin` defines a number of `public` instance methods that
plugins are expected to use or override: `hasPermission(String alias)`,
`getPermissionState(String alias)`, `requestPermissionForAlias(...)`,
`saveCall(PluginCall)`, `freeSavedCall()`, `notifyListeners(...)`, and others.

When generating helpers on a `Plugin` subclass, do not declare a method with
the same name and signature as one of these — the JVM treats it as an
override, and Java rejects narrowing visibility:

```java
// REJECTED at compile time: hasPermission is public on Plugin.
private boolean hasPermission(String alias) {  // ❌
    return getPermissionState(alias) == PermissionState.GRANTED;
}
```

Two acceptable shapes:

1. **Rename the helper** so it does not collide:

   ```java
   private boolean isPermissionGranted(String alias) {  // ✅
       return getPermissionState(alias) == PermissionState.GRANTED;
   }
   ```

2. **Match the parent's visibility** if you genuinely intend to override:

   ```java
   @Override
   public boolean hasPermission(String alias) {  // ✅
       // custom logic
       return super.hasPermission(alias);
   }
   ```

The compiler error reads `<method> in <Subclass> cannot override <method> in
Plugin; attempting to assign weaker access privileges; was public`. When that
appears, check whether the helper name overlaps with a public method on
`Plugin` and rename or widen visibility.

## Java File and Class Names

Every Java source file may contain at most one `public` class, and the file
name must match that public class name. When the plugin uses a separate
implementation class, place each public class in its own file: bridge in
`<ClassName>Plugin.java`, implementation in its own descriptive file (often
`<ClassName>Impl.java` or `<ClassName>.java`).

Kotlin does not enforce this rule, so when generating Kotlin do not blindly
mirror Java's file layout — a single `.kt` file may contain multiple top-level
classes. When generating Java, always pair file names with public class names.

## Where `notifyListeners()` Is Callable

`Plugin.notifyListeners(String name, JSObject data)` is `protected`. It can only
be called from within a class that extends `Plugin`. If a separate
implementation class, manager, service, broadcast receiver, or callback needs
to emit an event, dispatch through the plugin class rather than holding a
`Plugin` reference and calling `plugin.notifyListeners(...)`.

Two acceptable shapes:

1. **Return event data to the plugin and dispatch there** (preferred for
   synchronous flows):

   ```java
   // inside the Plugin subclass
   JSObject payload = implementation.compute();
   notifyListeners("changed", payload);
   ```

2. **Expose a public wrapper on the plugin class** (for background contexts
   that legitimately need to emit events while the plugin is loaded):

   ```java
   @CapacitorPlugin(name = "Example")
   public class ExamplePlugin extends Plugin {
       public void emit(String eventName, JSObject data) {
           notifyListeners(eventName, data);
       }
   }
   ```

Do not pass `Plugin` as a constructor parameter to an implementation class
purely so the implementation can call `plugin.notifyListeners(...)`. The
access modifier will reject it at compile time.

## Do Not Shadow `Plugin` API Methods

`com.getcapacitor.Plugin` already exposes a number of `public` methods that
plugin subclasses commonly want to use or "wrap" with helpers. Java rejects
overrides that narrow visibility, so a `private` helper with the same name and
signature as a `public` `Plugin` method fails to compile with
`<method> in <Subclass> cannot override <method> in Plugin: attempting to
assign weaker access privileges; was public`.

Common `Plugin` methods to be aware of when generating helpers on the bridge
class:

- `hasPermission(String alias)`
- `getPermissionState(String alias)`
- `requestPermissionForAlias(...)`, `requestPermissionForAliases(...)`,
  `requestAllPermissions(...)`
- `getContext()`, `getActivity()`, `getBridge()`, `getConfig()`
- `load()`, `handleOnConfigurationChanged(...)`

Three acceptable shapes:

1. **Use the inherited method directly.** If `Plugin.hasPermission(alias)`
   already returns the desired boolean, do not declare a helper — call the
   inherited method.
2. **Override with matching `public` visibility.** If the override needs new
   behavior, declare it `public`, not `private` or default-package, and call
   `super.<method>(...)` when delegation is required.
3. **Pick a different name.** For genuinely new helpers, name them so they do
   not collide with `Plugin`'s API surface (e.g., `isPermissionGranted(...)`
   rather than `hasPermission(...)`).

This rule applies symmetrically on iOS for `CAPPlugin` overrides — Swift
allows narrowing `public` to `private` on a non-override declaration, but if
an `@objc override` shadows a parent method, the override must keep the
parent's access level.

## Async Activity Results

When the plugin starts a system UI flow that returns a result (chooser, photo
picker, document picker, OAuth, settings, share-with-result), use Capacitor's
activity-result plumbing. Do not call `activity.startActivity(...)` followed by
`call.resolve()` synchronously — the resolve fires before the user picks
anything.

```java
startActivityForResult(call, intent, "onResult");

@ActivityCallback
private void onResult(PluginCall call, ActivityResult result) {
    JSObject ret = new JSObject();
    // map result.getData() into ret as needed
    call.resolve(ret);
}
```

## Background and Lifecycle Event Dispatch

Some plugins receive events from contexts that run outside the plugin's
lifecycle: `FirebaseMessagingService`, broadcast receivers, intent filters,
deep-link handlers, `Application.ActivityLifecycleCallbacks`, app shortcut
targets. The plugin instance may not be loaded when these events arrive.

Required pattern:

1. Implement the platform-specific class as a real subclass of the platform
   type (for example, extend `FirebaseMessagingService`). Do not generate a
   stand-alone class with a service-like name and unused imports — the runtime
   will not invoke it.
2. From the background class, write the payload to a queue or shared store
   keyed by event name.
3. In the plugin's `load()`, drain the queue and dispatch through
   `notifyListeners(...)` (which is in scope inside `load()`).
4. While the plugin is loaded, the background class may call a static accessor
   on the plugin's class object to deliver events directly. Never hold a
   `Plugin` reference across process boundaries.

Generated output for plugins of this shape must include the appropriate
manifest `<service>`, `<receiver>`, or `<intent-filter>` registrations and
README setup notes for any third-party SDK the app developer must install
(FCM, APNs, OAuth providers, etc.). Mark these as required app-side setup,
not plugin-internal.

## Verification

Run:

```bash
npm run verify:android
```

If verification fails, sync Gradle in Android Studio and check compile SDK,
Android Gradle Plugin, Kotlin, Java, and dependency versions.
