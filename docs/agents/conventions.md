# Conventions — kellerai-oss-template

Tier-2 detail for `AGENTS.md`. Authoritative source for commit, branch, PR,
citation, and validation conventions. When a convention changes, change it here
first.

## Commits — Conventional Commits

Every commit subject follows `<type>(<scope>): <subject>`.

- **`<type>`** — one of: `feat`, `fix`, `docs`, `chore`, `refactor`, `ci`,
  `revert`, `test`, `build`, `perf`. Use `ci` for workflow changes; `docs` for
  CHANGELOG, README, and agent-doc edits.
- **`<scope>`** — optional; names the area touched: `conformance`, `template`,
  `scripts`, `docs`, `agents`, `ci`. Omit for repo-wide changes.
- **`<subject>`** — imperative mood, ≤ 50 characters, no trailing period.

```text
feat(conformance): add gitignore_coverage rule
fix(scripts): handle shallow clone in branch enumeration
docs(agents): expand adoption-guide troubleshooting
chore(ci): pin setup-opa action to commit SHA
revert(conformance): undo artifact_dir default change
```

Commit body is optional. When present: explains *why*, one blank line after
the subject, wrapped at 72 characters.

`commitlint` validates every commit message in CI and in the pre-commit hook.
A non-conforming message fails the build — there is no bypass.

## Branches

The default branch is **`main`**. `master` is forbidden and blocked by the
`forbidden_branch` conformance rule.

| Work type | Pattern | Example |
|-----------|---------|---------|
| Agent work | `<agent>/<scope>` | `claude/fix-integrity-rule` |
| Human feature | `feat/<scope>` | `feat/add-rag-config-type` |
| Human fix | `fix/<scope>` | `fix/scanner-shallow-clone` |
| Docs | `docs/<scope>` | `docs/adoption-guide` |
| CI / chore | `chore/<scope>` | `chore/pin-actions` |
| Revert | `revert/<scope>` | `revert/artifact-dir-default` |

## Branch edge cases (common agent errors)

- **Never work on `main` directly.** Cut a branch before the first commit. If
  you find yourself on `main`, branch now — before committing.
- **Always base off the latest `main`.** Never branch from another in-flight
  branch.
- **Continuing another agent's branch:** keep the existing `<agent>/<scope>`
  name — do not rename it to your own agent ID.
- **Multi-scope changes:** prefer one scope per branch. If the change genuinely
  spans scopes, omit `<scope>` from the branch name rather than inventing a
  compound one. Do the same in the commit subject.
- **`<scope>` casing:** lowercase, hyphen-separated (`policy-integrity`, not
  `policyIntegrity`).
- **Revert branches:** use `revert/<scope>`; commit type is `revert`.
- **Commit type for housekeeping:** CHANGELOG edits = `docs`; workflow or
  `.github/` changes = `ci`; `AGENTS.md`/`CLAUDE.md`/`docs/agents/**` = `docs(agents)`.
- **Worktrees** are fine — the branch inside the worktree follows the same
  `<agent>/<scope>` convention.
- **Fork PRs:** external contributors work from a fork and open a PR against
  this repo's `main`. Never from the fork's own `main` branch.
- **Imperative mood:** "add rule" not "adds rule" or "added rule". No trailing period.
- **Commit bodies** wrap at 72 characters.

## Pull requests

PRs are required for publishable files: `conformance/**`, `template/**`,
`scripts/**`, `docs/**`, `README.md`, `AGENTS.md`, `CLAUDE.md`. Staging files
(anything matched by `.gitignore`) may be edited directly.

A PR description states: what changed, why it changed, how it was verified
(opa check + opa eval output or ajv output), and the semver classification
(major / minor / patch).

## Citations

- **Internal references** use `file:line` — e.g.
  `conformance/conformance.rego:48` for the `data_sentinel` rule. Cite the
  absence of a thing as precisely as its presence.
- **External references** use a full bibliographic citation: author(s), title,
  venue, year. Never cite from memory; verify the source first.

## Validation workflow

```bash
# Policy syntax and type check
opa check conformance/

# Full test suite
opa test conformance/

# Evaluate the summary against a snapshot
opa eval -d conformance/ -i repo-structure.json \
  'data.kellerai.oss.conformance.summary'

# For json-schema / rag-config repos: compile schemas
ajv compile -s schemas/*.json

# For json-schema repos: validate examples
ajv validate -s schemas/foo.json -d examples/foo.json
```

Run `opa check` before `opa test` — a syntax error will cause misleading test
failures. Fix syntax errors first.
