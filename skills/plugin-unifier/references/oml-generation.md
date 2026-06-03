# OML Generation — Phase 2

This phase is invoked separately, after the developer has reviewed and confirmed
Phase 1 output (both native plugin repos). The skill generates or updates the
**OutSystems Plugin** — a module of type **Mobile Library** whose `.oml` file
wraps both native plugins and exposes their functionality as OutSystems **client
actions** and **UI blocks**.

This only applies to ODC. The skill does not generate the OML for O11.
However, the OML is very similar in ODC and O11, so the ODC output serves as
the basis for O11 as well.

Optionally, the OML may include JavaScript code for PWA support. This code does
not live in the Cordova or Capacitor repos — it lives in the OML, and may also
have a private GitHub repo for source control (e.g. a `-PWA` suffixed repo for
the plugin's PWA code).

---

## Modes

- **Create new OML** — no existing Mobile Library. Generate from scratch:
  Extensibility Configurations JSON + Structures + Static Entities + Licenses
  Block + one client action per app-initiated method + one UI block per
  event-driven method.
- **Adapt existing OML** — a Mobile Library already exists. Update the
  Extensibility Configurations JSON and reconcile client actions and UI blocks:
  add new ones, update changed ones, flag removed methods for the developer.
  **Removing a client action or UI block is a breaking change for app consumers
  — never remove silently.**

In both modes, present the proposed OML changes to the developer for
confirmation before writing anything.

---

## Extensibility Configurations JSON

References both plugins so OutSystems knows which native plugins to include at
build time:

- The **Cordova plugin** by git URL:
  `https://github.com/OutSystems/cordova-outsystems-{plugin}`
- The **Capacitor plugin** by npm identifier: `@capacitor/{plugin}`

Both references are required in ODC (Cordova + Capacitor builds). In O11, only
the Cordova reference is needed.

---

## Structures and Static Entities

Generate the OutSystems Structures and Static Entities that correspond to the
types in the confirmed API spec:

- One **Structure** per options or result type (e.g. `PhotoOptions`, `Photo`) —
  one attribute per field, typed to match.
- One **Static Entity** per string enum (e.g. `CameraSource`,
  `CameraResultType`) — one record per enum value.

These are used as input/output parameter types in Client Actions and as payload
types in UI blocks.

---

## Licenses Block

Include a Licenses block in the OML listing the open-source licenses for the
native dependencies bundled by the plugin.

---

## Client Actions

For each method in the confirmed API spec that is **app-initiated** (i.e. the
OutSystems app calls the plugin directly), generate one client action:

- **Input parameters** — one per option key, typed to match the method's options
  object.
- **Output parameters** — one per key in the method's return type, typed to
  match.
- **A JS node** with JavaScript code that calls the Cordova or Capacitor plugin
  directly, using a runtime conditional.

JS node template:

```javascript
if (typeof(Capacitor) !== "undefined") {
    // Capacitor runtime (ODC)
    window.CapacitorPlugins.{Plugin}.methodName(options)
        .then(function(result) {
            // map result keys to output parameters
            $resolve();
        })
        .catch(function(error) {
            $reject(error);
        });
} else {
    // Cordova runtime (O11)
    cordova.plugins.{Plugin}.methodName(
        options,
        function(result) {
            // map result keys to output parameters
            $resolve();
        },
        function(error) {
            $reject(error);
        }
    );
}
```

---

## UI Blocks

Plugins that surface **events** (rather than respond to direct calls) also
require UI blocks. A UI block handles events fired by the native plugin,
allowing the OutSystems app to react accordingly.

Generate a UI block for each **event-driven method** — i.e. methods where the
native plugin initiates the call rather than the OutSystems app.

Each event-driven method produces one UI block:

- The UI block receives the event payload as input parameters (one per payload
  key).
- It exposes an **On{EventName}** event handler that the OutSystems app wires up
  to its own logic.
- Internally, a JS node registers the listener:
  `cordova.plugins.{Plugin}.addListener('{eventName}', callback)`

Example: a push notifications plugin with a `notificationClicked` event produces
a `NotificationClicked` UI block with an `OnNotificationClicked` handler.
