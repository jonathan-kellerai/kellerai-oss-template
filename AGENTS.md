# AGENTS.md — kellerai-oss-template

This repository is the **conformance authority and bootstrap scaffold** for the kellerai family of
open-source repositories — an OPA/Rego policy that machine-checks structural compliance, plus
tokenized file templates that stamp new conformant repos in one command.

**Humans read [README.md](README.md). Agents start here.**
This is the Tier-1 entry point. For deeper detail, load files under `docs/agents/` on demand.

## What this repo IS

- An **OPA/Rego conformance policy** (`conformance/conformance.rego`, package
  `kellerai.oss.conformance`) that validates any repo's file/directory structure against the
  kellerai OSS publication standard.
- A **data-driven manifest** (`conformance/data.json`) — the single source of truth for required
  files, directories, content assertions, and artifact-type rules.
- A **reusable GitHub Actions workflow** (`.github/workflows/conformance.yml`) that sibling repos
  call to run the policy on every push and pull request.
- A **bootstrap script** (`scripts/bootstrap.sh`) that generates a conformant repo tree from
  `template/_files/` using token substitution.
- The **prose publication standard** (`standard/OSS-PUBLICATION-STANDARD.md`).
- A **trust-dial verdict policy** (`conformance/trust_dial.rego`) that gates merges on a
  tier-based trust score; state and decision trace land in `audit/`.
- A **blast-radius pulse policy** (`conformance/blast_radius.rego`) that asserts every in-scope
  file is reachable from `conformance/affects.json`.
- A **LaaS conformance policy** (`conformance/laas/`) — machine-checkable rules for the
  LaaS proposal; prose and standards renderings in `docs/laas/`.
- Licensed **Apache-2.0** — see `LICENSE` and `NOTICE`.
- Artifact type: `rego-policy`. Owner: `jonathan-kellerai`.

## What this repo is NOT

- There is **no application runtime** here — no Python, TypeScript, Go, or compiled output.
- The **bootstrap script generates files only** — it does not `git init`, commit, or push.
- The **reusable workflow** is the CI integration point; it is not a standalone tool.
- Consumer repos that call the centralized workflow do **not** vendor `conformance.rego` —
  the workflow checks out this repo at `${{ job.workflow_sha }}` (the pinned reusable-workflow
  commit SHA) and runs the policy from here.

## File layout — agent reading order

Load the file that answers your question.

| Question | Read |
|----------|------|
| What is this project? | `README.md` |
| The full prose publication standard | `standard/OSS-PUBLICATION-STANDARD.md` |
| Conformance rules in detail | `conformance/README.md`, `docs/conformance-policy.md` |
| The manifest (required files, content assertions) | `conformance/data.json` |
| The Rego policy source | `conformance/conformance.rego` |
| The policy test suite | `conformance/conformance_test.rego` |
| Trust-dial verdict policy + data | `conformance/trust_dial.rego`, `conformance/trust_dial_data.json` |
| Blast-radius pulse policy + manifest | `conformance/blast_radius.rego`, `conformance/affects.json` |
| LaaS conformance policy | `conformance/laas/laas.rego`, `conformance/laas/README.md` |
| LaaS prose and standards renderings | `standard/LAAS.md`, `docs/laas/` |
| Branch governance rules | `docs/branch-governance.md` |
| How to adopt conformance in an existing repo | `docs/adoption-guide.md` |
| What a term means | `docs/agents/glossary.md` |
| Commit / branch / PR conventions (full detail) | `docs/agents/conventions.md` |
| How to cite this repo | `docs/agents/citation.md` |
| How conventions are enforced | `docs/agents/enforcement.md` |

Key source paths:

- `conformance/conformance.rego` — 376 lines; `deny` families: `data_sentinel`, `required_file`,
  `required_dir`, `required_github_file`, `required_agent_doc`, `required_script`,
  `artifact_type_known`, `artifact_dir`, `agents_md_length`, `claude_md_length`,
  `claude_md_import`, `readme_agent_footer`, `gitignore_coverage`, `forbidden_branch`,
  `primary_validator_wired`, `trust_dial_wired`, `policy_integrity`, `policy_integrity_manifest`,
  `affects_manifest_complete`.
- `conformance/data.json` — drives both the policy and `bootstrap.sh`; edit here to add a rule.
- `scripts/scan-repo-structure.sh` — emits `repo-structure.json` (input to `opa eval`); reads
  tracked files via `git ls-files`, captures `file_meta` for `AGENTS.md`/`CLAUDE.md`/`README.md`/
  `.gitignore`, branch list, CI `uses:` lines, and the `conformance.rego` SHA-256 digest.
- `scripts/bootstrap.sh` — flags: `--name`, `--artifact-type`, `--license`, `--noun`, `--out`
  (required); `--validator`, `--artifact-dir`, `--owner`, `--author`, `--description`, `--force`
  (optional).

## Conventions agents MUST follow

- **Default branch is `main`.** Never create or use `master`.
- **Conventional Commits.** `<type>(<scope>): <subject>` — subject ≤ 50 chars, imperative mood.
  Types: `feat`, `fix`, `chore`, `docs`, `refactor`. Scope recommended: `conformance`, `template`,
  `scripts`, `docs`, `standard`.
- **Branch naming.** Agent work: `<agent>/<scope>` (e.g. `claude/fix-gitignore-rule`,
  `codex/add-rag-config-type`). Human work: `feat/*`, `fix/*`, `docs/*`, `chore/*`.
- **PRs for publishable files.** Edits to `conformance/**`, `template/**`, `scripts/**`,
  `standard/**`, `docs/**`, or `README.md` require a pull request. Policy changes must pass
  `opa check` and `opa test`. Staging files (matched by `.gitignore`) may be edited directly.
- **Semver discipline.** Every policy or template change updates `CHANGELOG.md`.
  Adding a new required file or tightening a rule = **major**; adding an optional rule or new
  artifact type = **minor**; doc/comment fix = **patch**.
- **Never delete a file** without explicit maintainer permission.
- **Cite precisely.** Internal references use `file:line`; external references use a full
  bibliographic citation.
- **Policy integrity.** After changing `conformance/conformance.rego`, refreeze
  `data.policy_integrity.expected_digest` in `conformance/data.json` before committing.

Full conventions, edge cases, and examples: `docs/agents/conventions.md`.

## Open questions

Surface these when proposing amendments — do not silently assume an answer.

1. **`outcome_signal` equivalence for policy violations.** The conformance workflow maps
   `error`-severity to CI failure and `warning` to a report. Trust-dial now provides a
   decision-trace (`audit/decision-trace.jsonl`) for per-merge attribution, but a formal
   ELO/KoTH signal mapping for inter-session scoring remains unresolved.
2. **Multi-tenant repos.** The policy has no `tenant_id` concept; the rules assume a single-owner
   repo. Multi-tenant scenarios are out of scope for v0.1.

## Tier-2 references — load on demand

- `docs/agents/conventions.md` — Conventional Commits detail, branch edge cases, PR discipline.
- `docs/agents/citation.md` — Apache-2.0 attribution, BibTeX, `CITATION.cff` usage.
- `docs/agents/glossary.md` — artifact type, conformance manifest, policy integrity, bootstrap
  tokens, `repo-structure.json` schema, `kellerai.oss.conformance` surface rules.
- `docs/agents/enforcement.md` — how the reusable workflow is versioned and pinned; the
  `policy_integrity` self-tamper detection mechanism; the digest refreeze procedure.
