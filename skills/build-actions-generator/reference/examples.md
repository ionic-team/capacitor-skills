# Build Action Examples

This file contains complete, realistic `buildAction.json` examples. It will
grow to cover common plugin scenarios — see also `reference/common-scenarios.md`
(planned) for pattern-level guidance.

---

## Microsoft Azure AD / MSAL Authentication

Both platforms register the OAuth redirect scheme, declare authenticator app
visibility, request biometric permissions, and share a keychain token cache.

Both variables are mandatory — there is no sensible default for a per-app
client ID or URL scheme, so the developer must supply them in ODC Studio.

```json
{
  "variables": {
    "CLIENT_ID": {
      "type": "string"
    },
    "APP_SCHEME": {
      "type": "string"
    }
  },
  "platforms": {
    "android": {
      "manifest": [
        {
          "file": "AndroidManifest.xml",
          "target": "manifest",
          "merge": "<queries>\n    <package android:name=\"com.azure.authenticator\" />\n    <package android:name=\"com.microsoft.intune\" />\n    <package android:name=\"com.microsoft.windowsintune.companyportal\" />\n</queries>\n"
        },
        {
          "file": "AndroidManifest.xml",
          "target": "manifest/application",
          "merge": "<activity android:name=\"com.microsoft.identity.client.BrowserTabActivity\" android:exported=\"true\">\n    <intent-filter>\n        <action android:name=\"android.intent.action.VIEW\" />\n        <category android:name=\"android.intent.category.DEFAULT\" />\n        <category android:name=\"android.intent.category.BROWSABLE\" />\n        <data android:scheme=\"msauth\" android:host=\"$CLIENT_ID\" />\n    </intent-filter>\n</activity>\n"
        },
        {
          "file": "AndroidManifest.xml",
          "target": "manifest",
          "merge": "<uses-permission android:name=\"android.permission.USE_BIOMETRIC\" />\n<uses-permission android:name=\"android.permission.USE_FINGERPRINT\" />\n"
        }
      ],
      "gradle": [
        {
          "file": "app/build.gradle",
          "target": {
            "dependencies": null
          },
          "replace": {
            "implementation": "'com.microsoft.identity.client:msal:5.+'"
          }
        }
      ]
    },
    "ios": {
      "plist": [
        {
          "replace": false,
          "entries": [
            {
              "CFBundleURLTypes": [
                {
                  "CFBundleURLSchemes": [
                    "msauth.$CLIENT_ID",
                    "$APP_SCHEME"
                  ]
                }
              ]
            },
            {
              "LSApplicationQueriesSchemes": [
                "msauthv2",
                "msauthv3"
              ]
            },
            {
              "NSFaceIDUsageDescription": "Allows authentication using Face ID."
            }
          ]
        }
      ],
      "entitlements": {
        "replace": false,
        "entries": [
          {
            "keychain-access-groups": [
              "$(AppIdentifierPrefix)com.microsoft.adalcache",
              "$(AppIdentifierPrefix)com.microsoft.identity.universalstorage"
            ]
          }
        ]
      }
    }
  }
}
```
