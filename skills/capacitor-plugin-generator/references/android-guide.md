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

For system-wide screen brightness:

- Declare `android.permission.WRITE_SETTINGS` in the generated Android manifest
  or README setup instructions.
- Check access with `Settings.System.canWrite(context)`.
- Request access by opening `Settings.ACTION_MANAGE_WRITE_SETTINGS` with the
  current package URI.
- Return a `prompt` status after opening settings because the plugin cannot
  synchronously wait for the user to grant access.
- Before writing `Settings.System.SCREEN_BRIGHTNESS`, set
  `Settings.System.SCREEN_BRIGHTNESS_MODE` to manual.
- Convert between Android's `0..255` brightness setting and the TypeScript
  contract's `0..1` value.

For app/activity-only brightness:

- Use `getActivity().getWindow().getAttributes().screenBrightness`.
- Clamp values to `0.0f..1.0f`.
- Restore system brightness by setting
  `WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE`.
- No `WRITE_SETTINGS` access is required for activity-only brightness.

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
