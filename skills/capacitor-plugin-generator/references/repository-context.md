# Repository Context

Repository-local instructions override the generic command examples in this
skill. Before running scaffold, build, test, browser, or publishing checks,
read the target repository's agent guidance and package-manager signals.

## Instruction Discovery

Check, in order:

1. `AGENTS.md` or similarly scoped agent instructions in the repository root
   and relevant parent directories.
2. Project docs that state command or release policy.
3. Package-manager lockfiles and scripts: `bun.lock`, `bun.lockb`,
   `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, and `package.json`.

Use the most specific instruction that applies to the current path. If local
instructions conflict with generic examples in this skill, follow the local
instructions and mention the translation in the result.

## Command Runner Selection

The examples in this skill use `npm` and `npx` because those are the standard
public Capacitor documentation commands. Do not blindly copy them into a
repository with a different command policy.

| Target context | Command rule |
| --- | --- |
| Public README, docs, tutorials, marketing copy | Prefer standard `npm` / `npx` snippets unless that project's docs explicitly use another tool. |
| Repository-local commands | Use the repository's required package manager and script runner. |
| Bun-enforced repositories | Use `bun`, `bun run`, and `bunx` instead of `npm`, `npm run`, and `npx`. |
| No instruction and no lockfile signal | Use the standard Capacitor examples from this skill. |

Common translations:

| Standard example | Bun-enforced equivalent |
| --- | --- |
| `npm install` | `bun install` |
| `npm run build` | `bun run build` |
| `npm run verify` | `bun run verify` |
| `npm test` | `bun test` when the repository uses Bun test, otherwise the repository's `test` script via `bun run test`. |
| `npx cap sync ios` | `bunx cap sync ios` |
| `npx @capacitor/create-plugin@latest ...` | `bunx @capacitor/create-plugin@latest ...` |

Do not replace real user-provided tokens, API keys, or secrets with placeholders
while editing repository files. Preserve the value unless the user explicitly
asks for a rotation or redaction.

## Capgo Plugin Repositories

When a Capgo plugin repository or template `AGENTS.md` requires Bun, use Bun
for every command you execute in that repository. Keep npm/npx only in public
documentation or marketing content where the instructions say docs should use
the standard ecosystem command.

If the repository is based on the Capgo plugin template, prefer the template's
initialization script before implementing real plugin logic:

```bash
bun run init-plugin <plugin-slug> [ClassName] [app.capgo.packageid] [GitHubOrg] [android-lang]
```

For Kotlin Android output with the default Capgo org, pass the org as the
fourth argument and `kotlin` as the fifth argument:

```bash
bun run init-plugin downloader CapacitorDownloader app.capgo.downloader Cap-go kotlin
```

After generating a real plugin copy from the template:

- Change the remote away from the template before pushing.
- Remove bootstrap-only template scripts and files as directed by the local
  `AGENTS.md`.
- Keep the README API sections generated from `src/definitions.ts`; update
  JSDoc and run docgen instead of hand-editing generated API tables.
- Maintain both CocoaPods and Swift Package Manager support when the template
  requires both.
- Follow the repository's Capacitor major-version policy. If it states the
  plugin major follows Capacitor major and new plugins start at `8.0.0`, apply
  that policy for generated package metadata.
- Treat `CHANGELOG.md` as CI-managed when local instructions say not to edit it.

For Capgo public-release work, also check whether local instructions require:

- A public `Cap-go/capacitor-<plugin-slug>` repository.
- Repository description beginning with `Capacitor plugin for ...`.
- Repository homepage pointing to
  `https://capgo.app/docs/plugins/<plugin-slug>/`.
- A generated GitHub social preview asset uploaded through GitHub settings when
  API access is unavailable.
- A website documentation pull request covering the plugin registry, docs
  index, plugin docs pages, tutorial page, sidebar/search config, and icon
  assets when applicable.
- README CTA and banner tracking values preserved or updated to the plugin's
  real slug.

## Pull Requests, CI, and Review Comments

When repository instructions define a PR workflow, follow it. For the Capgo
workflow:

- Open PRs as draft.
- Run the relevant local checks before pushing.
- Wait for CI to finish; fix failures and rerun checks until they pass.
- Only mark the PR ready for review after CI passes.
- If automated review comments appear, wait until any "review in progress"
  state is gone, address actionable comments, resolve them, and rerun checks.

If CI or review state cannot be observed from the available credentials, say so
explicitly and keep the PR draft.

## Browser Automation

Use headless browser automation by default. Use a visible browser only when the
user needs to interact with the session or local instructions require a manual
authenticated web flow.
