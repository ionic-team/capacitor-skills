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
- [ ] Every optional option is defaulted in **native** code on both platforms (not only in the JS wrapper), and iOS option structs decode optionals with `decodeIfPresent` (a missing optional must not reject the call when Android tolerates it).
- [ ] **Every option declared in the contract is actually consumed in native code — or explicitly documented as unsupported.** An option that appears in `src/definitions.ts` (and the Cordova JS bridge) but is read by **no** native bridge is a silent functional gap: the method advertises a capability it never delivers. Note this is *not* caught by the parity rules above — a declared-but-dead option is ignored **symmetrically** on all four native surfaces, so method names, option keys, and action strings still match perfectly. Verify it explicitly: for each option key, grep it across `android/` and `ios/` of **both** plugins; if it has zero native readers, either implement it, drop it from the contract, or (if intentionally unsupported, e.g. on one platform) document it in the README / `ios/NOTES.md`. *(Distinct from the defaulting rule above: that one is about **symmetric handling of consumed** optionals; this one is about **completeness** — no declared-but-unconsumed options.)*

---

## Common Mismatches

| Pattern | Risk |
|---------|------|
| camelCase vs snake_case option keys | Silent data loss at runtime — native bridges receive `undefined` for misnamed keys |
| Method renamed on one side | The OML JS node will call the wrong action and get an unhandled error |
| Action string capitalisation differs | Android `when` is case-sensitive; iOS selector must match exactly |
| Permission type name differs | OML cannot map permission states correctly across platforms |
| Option declared in `definitions.ts` but read by no native bridge | Silent functional gap — the method ignores the option on every platform, so it advertises a capability it never delivers. Symmetric, so the parity checks above all pass; only the completeness check catches it. |
