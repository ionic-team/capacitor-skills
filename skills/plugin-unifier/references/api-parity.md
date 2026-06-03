# API Parity Rules

These rules must be verified before declaring Phase 1 complete. Any violation
is a bug in the generated output, not a design trade-off.

---

## Rules

1. **Same method names.** Every method in the Capacitor plugin must have a
   counterpart with the identical name in the Cordova JS bridge and native bridge.

2. **Same option keys.** Option object keys must match exactly between both
   plugins — same names, same casing.

3. **Same return type shapes.** The shape of success response objects must match
   exactly — same keys, same casing.

4. **Same permission model.** Permission type names, state values (`granted`,
   `denied`, `prompt`, `prompt-with-rationale`), and the shape of
   `PermissionStatus` must match between both plugins.

5. **Same action names.** The action string passed to `cordova/exec` in
   `www/js/{plugin}.js` must match:
   - The `when` branch string in `execute()` on Android (`OS{Plugin}Plugin.kt`).
   - The `@objc(actionName:)` selector on iOS (`OS{Plugin}Plugin.swift`).
   - The `PLUGIN_NAME` constant must be `OS{Plugin}Plugin` (matching the
     `<feature>` name in `plugin.xml`).

---

## Verification Checklist

For each method in the agreed API spec, verify:

- [ ] Method name is identical in `src/definitions.ts` (Capacitor), `www/js/{plugin}.js` (Cordova JS bridge), and the native bridge classes on both sides.
- [ ] Every option key name is identical across both plugins.
- [ ] Every return object key name is identical across both plugins.
- [ ] The action string in `cordova/exec` matches the Android `when` branch and iOS selector exactly.
- [ ] `PermissionStatus` key names and `PermissionState` values are identical.
- [ ] Error codes use the `OS-PLUG-<PLUGIN>-NNNN` format on both platforms and both plugins. Every `reject`/`error` call passes a structured `{ code, message }` object, never a plain string.
- [ ] The same error codes are used for the same error conditions across both plugins.

---

## Common Mismatches

| Pattern | Risk |
|---------|------|
| camelCase vs snake_case option keys | Silent data loss at runtime — native bridges receive `undefined` for misnamed keys |
| Method renamed on one side | The OML JS node will call the wrong action and get an unhandled error |
| Action string capitalisation differs | Android `when` is case-sensitive; iOS selector must match exactly |
| Permission type name differs | OML cannot map permission states correctly across platforms |
