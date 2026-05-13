# Post-Migration Cleanup

Phase 12 work — runs only after the generator skill has produced a working
Capacitor plugin (passing `npm run verify` to the extent the local toolchain
allows). The goal is a single, reviewable migration trail and a clean working
copy ready to ship.

## What to Produce

1. A single `MIGRATION.md` at the Capacitor plugin root.
2. An updated `README.md` with consumer-facing migration notes.
3. A tidy working copy — no leftover scratch notes, status files, or stub
   directories.
4. (Mode A only) A correctly archived `.cordova-archive/` excluded from the
   published npm artifact.

## `MIGRATION.md` Structure

Use this exact section list. The reviewer is the audience.

```markdown
# Migration from Cordova

## Overview
- Original Cordova plugin: <name>@<version> (<repo url>)
- New Capacitor plugin: <npm name>@<version>
- Migration complexity: <simple|moderate|complex>
- Migration date: <YYYY-MM-DD>
- Capacitor equivalent mirrored (if any): <package@version>

## API Changes
- Callbacks → Promises (breaking)
- Positional arguments → named options object (breaking)
- Renamed methods: <old> → <new>
- Removed methods (and why)
- New methods (and why)

## Breaking Changes for Consumers
- Concrete before/after JS snippet showing the breakage
- Whether the new package replaces the old one or coexists

## Native Setup Required
### iOS
- Info.plist keys (exact entries)
- Podfile / SPM entries
- Entitlements (if any)

### Android
- AndroidManifest.xml entries (exact)
- Gradle dependencies
- Custom Maven repositories

## Configuration
- capacitor.config keys under `plugins.<PluginJSName>`
- Defaults
- Per-platform overrides (if any)

## Hook Migration
- Tier 1 hooks now in plugin's `package.json` `scripts` as
  `capacitor:{sync,copy,update}:{before,after}`
- Tier 2 hooks now in plugin's `package.json` `scripts` as
  `postinstall` / `preuninstall`
- Tier 3 blockers (resolved during migration) and the workaround chosen

## Known Limitations
- Anything the generator emitted with `unimplemented()` on web
- Platform-only features
- Cordova features intentionally dropped

## Verification Run
- `npm run verify:web` — pass | fail | skipped (reason)
- `npm run verify:ios` — pass | fail | skipped (reason)
- `npm run verify:android` — pass | fail | skipped (reason)
- Sample-app smoke check status

## References
- Original Cordova plugin source
- Capacitor equivalent (if mirrored)
- Capacitor plugin docs that informed the port
```

## Files to Remove

During analysis and generation, intermediate scratch files often accumulate.
Remove them before declaring Phase 12 complete:

- `MIGRATION_STATUS.md`, `CONVERSION_STATUS.md`
- `IMPLEMENTATION_TODO.md`, `IOS_TODO.md`, `ANDROID_TODO.md`
- `IOS_NOTES.md`, `ANDROID_NOTES.md`
- `API_MAPPING.md`, `BLOCKERS.md`, `UNSUPPORTED_PATTERNS.md`
- Any file whose content has been folded into `MIGRATION.md`

`git rm` (or `rm` then `git add`) each one. Do not leave duplicate sources of
truth.

## README Updates

The Capacitor plugin's `README.md` is the consumer-facing entry point. Update
the install section, usage section, and any migration callout.

Minimum updates:

1. Install command uses the npm package, not `cordova plugin add`.
2. Usage snippet shows `await Plugin.method({ ... })`, not `cordova.exec()`.
3. A "Migrating from <cordova-name>" subsection links to `MIGRATION.md`.
4. Permission / native setup notes are present in the README itself (not only
   in `MIGRATION.md`).

## Mode A Cleanup (`.cordova-archive/`)

If the user chose Mode A in Phase 1, the original Cordova source now lives
under `.cordova-archive/`. Confirm:

1. `.cordova-archive/` is excluded from the published npm artifact. Either
   add it to `.npmignore` or omit it from the `files` field in
   `package.json`.
2. `.cordova-archive/` is included in the git tree (not `.gitignore`d).
   Reviewers need it for diff.
3. The directory contains exactly the original Cordova layout — no scratch
   notes, no stub Capacitor files.

Suggested `package.json` `files` field for Mode A:

```json
{
  "files": [
    "android/",
    "dist/",
    "ios/Plugin/",
    "<PluginName>.podspec",
    "README.md",
    "MIGRATION.md"
  ]
}
```

`.cordova-archive/` is intentionally absent from `files`.

## Mode B Cleanup (Side-by-Side)

For Mode B, the original `cordova-plugin-<name>/` directory is untouched.
Confirm:

1. The new `capacitor-plugin-<name>/` directory is the only working copy.
2. The Cordova directory's README has a banner pointing at the new
   Capacitor package (only if the user controls both directories).
3. The Capacitor package's `repository.url` in `package.json` points at the
   new repo, not the Cordova one.

## Final Walkthrough

Before declaring Phase 12 done, the agent answers each prompt:

- Does `MIGRATION.md` exist at the plugin root with all sections filled?
- Are intermediate scratch files removed?
- Does `README.md` show consumer-facing usage and link to `MIGRATION.md`?
- Has every blocker that was resolved during migration been recorded with
  its chosen workaround?
- (Mode A) Is `.cordova-archive/` git-tracked and npmignore-excluded?
- Did the verify commands run, and is the result recorded?
- Did the sample app exercise every method in the new TypeScript surface?

If any answer is "no," Phase 12 is not complete. Do not announce completion
to the user until each check passes.

## What Not to Do

- ❌ Do not delete the Cordova source unless the user explicitly asks. Even
  in Mode A the source is archived, not deleted.
- ❌ Do not rewrite `MIGRATION.md` on every iteration. Treat it as the
  permanent record. Add a small "Updated <date>" stanza if revisions are
  needed.
- ❌ Do not commit verify failures as "known limitation." Either fix the
  generated code (return to the generator skill) or mark the platform
  `unimplemented()` explicitly.
- ❌ Do not bury blocker resolutions in PR descriptions. They belong in
  `MIGRATION.md` so future readers see the trail.
