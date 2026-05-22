# Contributing to kellerai-oss-template

Thanks for helping improve the kellerai OSS conformance system.
This repository holds an OPA/Rego policy, tokenized templates, and the prose publication standard —
there is no application code to build.

Agents should start at [AGENTS.md](AGENTS.md). It and the files under
[`docs/agents/`](docs/agents/) are the authoritative source for every convention summarized below.

## Before you start

- For anything beyond a typo, open an **issue** first using one of the
  [issue forms](.github/ISSUE_TEMPLATE):
  - `policy-bug.yml` — a conformance rule is wrong or produces a false positive/negative.
  - `policy-clarification.yml` — a rule or manifest field is ambiguous.
  - `policy-amendment-proposal.yml` — propose a new rule or a change to an existing one; captures
    semver impact and rationale.
  - `integration-question.yml` — how to adopt or wire in the conformance workflow.
- The default branch is `main`. Branch from it. Never commit to `main` directly,
  and never open a pull request from your fork's `main`.

## Branches and commits

- **Branch naming:** `<agent>/<scope>` for agent work (e.g. `claude/add-rag-config-rule`,
  `codex/fix-gitignore-coverage`); `feat/*`, `fix/*`, `docs/*`, `chore/*` for human work.
- **Commits** follow [Conventional Commits](https://www.conventionalcommits.org):
  `<type>(<scope>): <subject>`, imperative mood, subject ≤ 50 characters.
  Recommended scopes: `conformance`, `template`, `scripts`, `docs`, `standard`.
  `commitlint` enforces this as a hard CI gate.

Full edge-case guidance (multi-scope, hotfix branches, revert commits, working on `main`):
`docs/agents/conventions.md`.

## Validation

Before opening a pull request, run all three gates locally:

```bash
# 1. OPA syntax check and test suite
opa check conformance/
opa test conformance/

# 2. Generate a snapshot of this repo and evaluate it (self-conformance)
bash scripts/scan-repo-structure.sh > repo-structure.json
opa eval -d conformance/ -i repo-structure.json \
  'data.kellerai.oss.conformance.summary'

# 3. Sanitization check
bash scripts/check-sanitization.sh
```

All three must pass. CI additionally runs markdown lint and a link check.
Install the pre-commit hook with `lefthook install` (optional but recommended) to run
gates 1 and 3 automatically on every commit.

### Policy integrity — mandatory after editing conformance.rego

If you change `conformance/conformance.rego`, you must refreeze the integrity digest
before committing:

```bash
# Linux
sha256sum conformance/conformance.rego

# macOS
shasum -a 256 conformance/conformance.rego
```

Copy the hex digest into `conformance/data.json` at `policy_integrity.expected_digest`.
CI will fail if the live digest diverges from the manifest value.

### Bootstrap smoke test — mandatory after editing data.json or template/

Any change to `conformance/data.json` or `template/_files/` must be followed by a
bootstrap smoke test for each affected artifact type:

```bash
bash scripts/bootstrap.sh \
  --name smoke-test \
  --artifact-type json-schema \
  --license Apache-2.0 \
  --noun schema \
  --out /tmp/smoke-json-schema

bash scripts/scan-repo-structure.sh --root /tmp/smoke-json-schema \
  --artifact-type json-schema > /tmp/smoke.json

opa eval -d conformance/ -i /tmp/smoke.json \
  'data.kellerai.oss.conformance.errors'
```

The `errors` set must be empty for a conformant bootstrap output.

## Semver policy

This repository is versioned with Semantic Versioning:

- **major** — a tightened rule (new required file, stricter content assertion), a removed rule
  that consumers relied on, or a breaking change to `repo-structure.json` input shape.
- **minor** — a new optional rule, a new artifact type, a new token in `template/`, or a new
  helper script.
- **patch** — a clarification, comment fix, doc update, or example correction with no contract
  impact.

State the classification in your pull request. The PR template has a semver checklist.
Every schema change must update `CHANGELOG.md`.

## Pull request checklist

- [ ] Branched from `main`; the branch name follows the convention.
- [ ] Commit messages are valid Conventional Commits.
- [ ] `opa check conformance/` and `opa test conformance/` both pass.
- [ ] Self-conformance `opa eval` returns zero errors.
- [ ] `check-sanitization.sh` passes.
- [ ] If `conformance.rego` was changed: `data.policy_integrity.expected_digest` is refrozen.
- [ ] If `data.json` or `template/` was changed: bootstrap smoke test passes for affected types.
- [ ] `CHANGELOG.md` updated with the semver classification.
- [ ] The PR template's five sections are filled in.
- [ ] New vocabulary is added to `docs/agents/glossary.md`.

## Conduct

Be precise, cite your sources, and assume good faith.
Discussion happens on issues and pull requests.
