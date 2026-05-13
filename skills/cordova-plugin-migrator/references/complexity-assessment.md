# Complexity Assessment

Score every plugin you analyze. The score drives the `migration.complexity`
field in the YAML handoff and tells the user up front whether the migration is
straightforward, moderate, complex, or blocked.

## Output Values

| Value | Meaning |
| --- | --- |
| `simple` | Direct migration. No blockers, no Tier 3 hooks, no proprietary native deps, no `<config-file>` mutations beyond standard permission entries. |
| `moderate` | Migration is feasible but requires manual native setup, language modernization, or a small number of Tier 2 hooks. No Tier 3 hooks. |
| `complex` | Migration is feasible but expensive: extensive native dep work, multiple Tier 2 hooks, large API surface, or a custom Maven/Pod source. No Tier 3 hooks. |
| `blocked` | One or more issues prevent generator handoff. The Phase 10 checkpoint must stop and request user input. |

`blocked` is not "complex with vibes." It is a hard veto.

## Scoring Inputs

Combine these inputs. Any single input pushing into the `blocked` row makes
the overall value `blocked`.

### Method count (public JS API)

| Methods | Signal |
| --- | --- |
| 1–3 | simple |
| 4–10 | moderate |
| 11–20 | complex |
| 20+ | complex; consider splitting into multiple plugins |

### Lines of native source (iOS + Android combined)

| LOC | Signal |
| --- | --- |
| < 500 | simple |
| 500–2,000 | moderate |
| 2,000–5,000 | complex |
| 5,000+ | complex; recommend incremental platform-by-platform handoff |

### Native dependencies

| Footprint | Signal |
| --- | --- |
| System frameworks only (CoreLocation, AVFoundation, etc.) | simple |
| 1–3 public CocoaPods or Gradle deps with current versions | moderate |
| 4+ public deps OR any pod/dep requiring a version bump with breaking changes | complex |
| Any proprietary/private SDK (vendor-only AAR, license-key framework, private Maven) | blocked |
| Any `android.support.*` coordinate without Jetifier opt-in | blocked |

### Hooks (per `references/hooks-migration.md`)

| Hook mix | Signal |
| --- | --- |
| No hooks, or Tier 1 only | simple |
| Tier 1 + Tier 2 (≤ 3 hooks) | moderate |
| Tier 1 + Tier 2 (4+ hooks) | complex |
| Any Tier 3 hook | blocked |

### `<config-file>` and `<edit-config>` mutations

| Mutations | Signal |
| --- | --- |
| None, or standard permission strings only | simple |
| 1–3 manifest/plist edits with documented manual setup | moderate |
| 4+ edits, or edits to non-standard parents, or conditional edits | complex |
| Edits that mutate Cordova-specific files (`plugin.xml`, `config.xml`) at runtime | blocked |

### Language modernization

| Source | Signal |
| --- | --- |
| iOS Swift only, Android Kotlin only | simple |
| iOS Objective-C → Swift OR Android Java → Kotlin (single side) | moderate |
| Both sides need modernization | moderate (not complex on its own) |
| Mixed Objective-C/Swift in a way that forces a bridging header for new code | complex |

Language modernization alone does not push a plugin to `complex` or `blocked`.

### Capacitor equivalent availability

| Equivalent | Signal |
| --- | --- |
| Official `@capacitor/<name>` exists | shifts one tier toward `simple` (pin its wire format) |
| Capawesome/community port exists | shifts one tier toward `simple` |
| No equivalent | no adjustment |

Equivalents reduce risk because their `definitions.ts` pins the wire format
and listener names. The migrator skill can mirror them verbatim.

### Other blocker triggers (any → `blocked`)

- `plugin.xml` references source files that do not exist on disk.
- `<hook>` references scripts that cannot be opened, are obfuscated, or
  require Cordova CLI internals.
- `<js-module runs="true">` performs side effects that cannot be moved into
  an explicit `initialize()` or web-layer constructor (rare).
- `<dependency>` on another Cordova plugin that itself lacks a migration plan.
- The plugin advertises a feature whose native source is missing or stubbed.

## Worked Scoring Examples

### Example 1: `cordova-plugin-device` style

- 1 method (`getInfo`), ~150 LOC total.
- System frameworks only.
- No hooks.
- No `<config-file>` mutations.
- Official `@capacitor/device` equivalent exists.

→ `simple`. Mirror `@capacitor/device` `DeviceInfo` shape verbatim.

### Example 2: `cordova-plugin-camera` style

- 2 methods (`getPicture`, `cleanup`), ~800 LOC total.
- System frameworks + UIImagePickerController on iOS; Activity Intent on
  Android.
- No hooks.
- Permission entries in plugin.xml.
- Official `@capacitor/camera` equivalent exists.

→ `moderate`. Mirror `@capacitor/camera`'s `Photo`, `ImageOptions`,
`CameraResultType`, and `CameraSource` enums verbatim.

### Example 3: Custom analytics plugin with vendor SDK

- 6 methods, ~1,200 LOC.
- iOS: vendor `.framework` (license-key only).
- Android: vendor `.aar` from private Maven.
- 2 Tier 2 hooks (postinstall pod warmup).

→ `blocked` (proprietary SDKs). The Phase 10 checkpoint reports the SDK
names, the license/access requirement, and asks the user how to proceed.

### Example 4: Cordova → Capacitor payments plugin

- 6–10 methods (configure, setupApplePay, requestPayment, presentApplePay,
  etc.).
- Native: PassKit on iOS, Google Pay SDK on Android.
- No hooks.
- Permission strings: `NSAppleMusicUsageDescription`-style entries in
  plugin.xml (none) plus standard PassKit entitlements (manual setup).

→ `moderate`. Generator must mirror payment-method strings and event payload
shapes exactly; this is where a wire-format mismatch is most damaging.

## Reporting

In the human summary at Phase 10, surface the score and the dominant signal
that produced it:

```
Complexity: moderate
  - 6 public methods, ~1,800 LOC
  - 2 Gradle deps (public, current)
  - No hooks
  - Android Java → Kotlin modernization
```

In the YAML:

```yaml
migration:
  complexity: moderate
```

If the score is `blocked`, list the specific blockers under
`migration.blockers` — never collapse multiple blockers into a single string.
