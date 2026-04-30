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

## Verification

Run:

```bash
npm run verify:android
```

If verification fails, sync Gradle in Android Studio and check compile SDK,
Android Gradle Plugin, Kotlin, Java, and dependency versions.
