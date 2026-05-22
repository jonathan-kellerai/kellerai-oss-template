# AGENTS.md — {{REPO_NAME}}

This repository is the **{{REPO_NAME}}** {{ARTIFACT_TYPE}} artifact.

**Humans read [README.md](README.md). Agents start here.**
This file is the Tier-1 entry point: a table of contents for agent context.
It points at deeper Tier-2 files under [`docs/agents/`](docs/agents/) for agents that need more.

## What this repo IS

- A **{{ARTIFACT_TYPE}}** artifact maintained under the **{{LICENSE_ID}}** license.
- The load-bearing artifact is in [`{{ARTIFACT_DIR}}/`]({{ARTIFACT_DIR}}/).
- See [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).

## What this repo is NOT

- There is **no runtime code** here — no package, no build, no API to import.
  Do not invent code paths, modules, or call sites.
- There is **no issue tracker** in this repo.
  Work is tracked in GitHub Issues.
- The only verification command is `{{PRIMARY_VALIDATOR}}`.
  See [`docs/agents/conventions.md`](docs/agents/conventions.md).

## File layout — agent reading order

Read the file that answers your question — do not load the whole tree.

| Question | Read |
|----------|------|
| What is this project? | `README.md` |
| What does a term mean? | `docs/agents/glossary.md` |
| Commit, branch, PR rules | `docs/agents/conventions.md` |
| How to cite this repo | `docs/agents/citation.md` |
| How conventions are enforced | `docs/agents/enforcement.md` |
| The primary artifact | `{{ARTIFACT_DIR}}/` |

## Conventions agents MUST follow

- **Default branch is `main`.** Never create or use `master`.
- **Conventional Commits.** `<type>(<scope>): <subject>` — subject ≤ 50 chars,
  imperative mood. Types: `feat`, `fix`, `chore`, `docs`, `refactor`.
  Scope is optional but recommended.
- **Branch naming.** Agent work uses `<agent>/<scope>` — e.g.
  `claude/fix-typo`, `codex/clarify-field`. Human work uses
  `feat/*`, `fix/*`, `docs/*`, `chore/*`.
- **PRs for publishable files.** Edits to `{{ARTIFACT_DIR}}/**`, `docs/**`,
  or `README.md` require a pull request.
  Changes must pass `{{PRIMARY_VALIDATOR}}`.
  Edits to staging files (anything matched by `.gitignore`) may be made directly.
- **Never delete a file** without explicit maintainer permission.
- **Semver discipline.** Every artifact change updates `CHANGELOG.md`.
- **Cite precisely.** Internal references use `file:line`;
  external references use a full bibliographic citation.

Full detail: [`docs/agents/conventions.md`](docs/agents/conventions.md).

## Capability Roster

When a task needs a specialist capability, prefer the canonical plugin for the
domain. PR review is handled by `keller-pr-review`, a code-review tool run on
diffs — it is a workflow gate, not a domain capability.

| Domain | Canonical capability | Secondary |
| ------ | -------------------- | --------- |
| Session mining | `thoughtbox` | — |
| Capability analysis | `kellerai-repo-audit` | — |
| Repo architecture & scaffolding | `kellerai-repo-audit` | `kellerai-skill-creator` |
| Conformance & policy | `opa-rego` | `kellerai-grc` |
| CI/CD authoring | `git-workflow-tools` | `beads-workflow` |
| Governance & traceability | `kellerai-feature-spec` | `thoughtbox` |
| Documentation | `documentation-audit` | `claude-md-management` |

## Open questions

List any unresolved architectural questions here.
Surface them when proposing amendments — do not silently assume an answer.

## Tier-2 references

Deeper guidance — load on demand:

- [`docs/agents/conventions.md`](docs/agents/conventions.md) — Conventional Commits,
  branch naming, PR style, citation format, the `{{PRIMARY_VALIDATOR}}` workflow.
- [`docs/agents/citation.md`](docs/agents/citation.md) — how to cite {{REPO_NAME}}
  ({{LICENSE_ID}} attribution, BibTeX, `CITATION.cff`).
- [`docs/agents/glossary.md`](docs/agents/glossary.md) — load-bearing vocabulary.
- [`docs/agents/enforcement.md`](docs/agents/enforcement.md) — how conventions are enforced.
