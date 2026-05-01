# Testing and Workflow

Generated plugins must be verified as far as the local environment allows.
Report skipped checks clearly.

## Core Commands

```bash
npm install
npm run build
npm run docgen
npm run verify:web
npm run verify:ios
npm run verify:android
npm run verify
npm run lint
npm run fmt
```

Use platform-specific verify commands when the full native toolchain is not
available.

## Local Linking

To test the generated plugin from a sample app:

```bash
cd <plugin-root>
npm install
npm run build

cd <sample-app>
npm install
npm install ../<plugin-root>
npx cap sync
```

## Capacitor CLI Workflow

Use these commands intentionally:

| Command | When to use |
| --- | --- |
| `npx cap add ios` / `npx cap add android` | Add a native platform to a sample app that does not already have it. |
| `npx cap sync` | After installing the local plugin, changing native plugin code, changing dependencies, editing Capacitor config, or rebuilding web assets for native testing. |
| `npx cap copy` | After web-only sample app changes when native dependencies/config did not change. |
| `npx cap open ios` / `npx cap open android` | Open the native IDE for simulator/device selection, signing, Gradle sync, or manual platform inspection. |
| `npx cap run ios` / `npx cap run android` | Build and run the sample app on a simulator, emulator, or connected device. |

If generated native code, plugin metadata, permissions, dependencies, or config
changed, prefer `npx cap sync` over `npx cap copy`.

For web-only sample validation:

```bash
npm start
```

For native validation:

```bash
npx cap run ios
npx cap run android
```

## Review Checklist

- `src/definitions.ts` contains the complete contract with JSDoc and `@since`.
- `src/index.ts`, iOS `jsName`, and Android `@CapacitorPlugin(name)` match.
- `src/web.ts` uses dynamic registration, feature detection, and proper errors.
- iOS bridge methods are `@objc` and listed in `pluginMethods`.
- Android bridge methods are public and annotated with `@PluginMethod()`.
- Events use identical strings across all platforms.
- Permissions are explicit in API, native code, and generated docs.
- Dependencies are declared in the platform package files and documented.
- Sample app exercises every method and listener.
- README API docs come from `npm run docgen`.

## Unit Test Patterns

Native and web layers can be unit-tested without launching a full Capacitor
app. The patterns below are toolchain-agnostic recipes — drop in whichever
framework the scaffold provides (XCTest, JUnit, Jest).

### iOS — Mock `CAPPluginCall`

For unit tests of the bridge class, subclass `CAPPluginCall` and capture the
`resolve` / `reject` calls instead of invoking real Capacitor plumbing:

```swift
import XCTest
import Capacitor
@testable import ExamplePlugin

final class MockPluginCall: CAPPluginCall {
    var resolvedData: [String: Any]?
    var rejectedMessage: String?

    override func resolve(_ data: [String: Any]) { resolvedData = data }
    override func reject(_ message: String) { rejectedMessage = message }
}

final class ExamplePluginTests: XCTestCase {
    func testEcho() {
        let plugin = ExamplePlugin()
        let call = MockPluginCall(callbackId: "t",
                                  options: ["value": "hi"],
                                  success: { _, _ in },
                                  error: { _ in })
        plugin.echo(call)
        XCTAssertEqual(call.resolvedData?["value"] as? String, "hi")
    }
}
```

For async work, use `XCTestExpectation` and `waitForExpectations(timeout:)`.

### Android — Mock `PluginCall` with Mockito

Mock `PluginCall` directly; verify with `argThat`:

```java
import com.getcapacitor.JSObject;
import com.getcapacitor.PluginCall;
import org.junit.Test;
import static org.mockito.Mockito.*;

public class ExamplePluginTest {
    @Test
    public void echoResolvesValue() {
        PluginCall call = mock(PluginCall.class);
        when(call.getString("value")).thenReturn("hi");

        ExamplePlugin plugin = new ExamplePlugin();
        plugin.echo(call);

        verify(call).resolve(argThat(result ->
            "hi".equals(result.getString("value"))));
    }
}
```

For methods that need an Android `Context`, run with Robolectric:

```java
@RunWith(RobolectricTestRunner.class)
public class ContextDependentTest {
    @Test
    public void writesFile() {
        Context context = ApplicationProvider.getApplicationContext();
        // exercise plugin logic that needs a real Context
    }
}
```

### Web — Mock browser APIs on `globalThis.navigator`

Use `Object.defineProperty` to inject a fake API, then assert on the mock:

```typescript
import { ExampleWeb } from '../web';

describe('ExampleWeb', () => {
  let plugin: ExampleWeb;

  beforeEach(() => {
    plugin = new ExampleWeb();
    Object.defineProperty(globalThis.navigator, 'geolocation', {
      value: {
        getCurrentPosition: jest.fn((onSuccess) =>
          onSuccess({
            coords: { latitude: 1, longitude: 2, accuracy: 5 },
            timestamp: 0,
          })),
      },
      configurable: true,
    });
  });

  test('returns coords', async () => {
    const result = await plugin.getCurrentPosition();
    expect(result.latitude).toBe(1);
  });
});
```

The `configurable: true` flag is what lets a later test redefine the property
to simulate the API being unavailable.

## Hooks

If generated output needs package lifecycle hooks, prefer npm scripts and keep
them explicit in `package.json`. Do not generate Cordova hook patterns. If the
structured migration input includes tier 3 hooks, stop and ask for migration
analysis to resolve them before generation.

## Manual Validation Notes

Some plugin categories require real devices, credentials, or store-facing
configuration. Mark those as manual review items rather than claiming full
runtime correctness.
