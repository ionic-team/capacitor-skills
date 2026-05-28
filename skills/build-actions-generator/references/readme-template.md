# README Template for Build Actions

Use this structure when generating `build-actions/README.md`. Follow the
authoring rules in SKILL.md (Generation Guideline 5) to determine which
sections to include or omit.

---

```markdown
# <Plugin/App Name> Build Actions

<One short paragraph: what this plugin/app does and why native build
configuration is required — inferred from the generated actions.>

## What this configures

### Android
| Action | Purpose |
|--------|---------|
| `<action type>` | <what it sets up> |

### iOS
| Action | Purpose |
|--------|---------|
| `<action type>` | <what it sets up> |

## What requires additional setup

| Hook / element | Reason not mapped | Recommended approach |
|----------------|-------------------|----------------------|
| `<hook type>` | <why it can't be a build action> | Capacitor hook |

## Variables

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `VAR_NAME` | string | yes | — | What this value controls |

## ODC Setup

1. In ODC Studio, add `buildAction.json` as a resource and set **Deploy Action**
   to **Deploy to Target Directory**.
2. Configure extensibility to reference the file and resolve its variables.
   The path depends on the target:
   - **ODC app:** App > Edit app properties > Extensibility
   - **ODC Mobile Library (plugin):** Library > Edit library properties > Extensibility

   ```json
   {
       "buildConfigurations": {
           "buildAction": {
               "config": "$resources.buildAction.json",
               "parameters": {
                   "VAR_NAME": "value"
               }
           }
       }
   }
   ```

   Values in `parameters` can be hardcoded literals or extensibility setting references
   (`$extensibilitySettings.SettingName`). Use extensibility settings for any value that
   consuming apps should be able to configure. The plugin developer creates the settings
   in ODC Studio: right-click **Extensibility Settings** in the context pane →
   **Add Extensibility Setting**. For sensitive values (like API keys or tokens), set
   **Is Secret** to True — secret settings have no default and must be supplied in ODC
   Portal before generating a mobile package. The consuming app then sets values in
   ODC Portal → app → **Mobile distribution** → **Extensibility settings**.

3. Build in the ODC Portal using MABS 12 or greater:
   - **ODC app:** build the app directly.
   - **ODC Mobile Library (plugin):** consume the library in an ODC app, then
     build that app.
```
