# kellerai-oss-template

A conformance authority and bootstrap scaffold for the kellerai family of open-source repositories.

- **License:** Apache-2.0
- **Owner:** jonathan-kellerai
- **Artifact type:** rego-policy

---

## The problem

Six repositories are staged for public release under the `jonathan-kellerai` GitHub organization.
Each was created in a separate session, by a different agent, without a shared enforcement mechanism.
The result is structural drift: missing `CONTRIBUTING.md` files, divergent license declarations, absent
agent-docs directories, workflows that were never wired up.
A prose standard exists (`standard/OSS-PUBLICATION-STANDARD.md`) but prose cannot block a bad pull request.

## The solution

This repository is both the **conformance authority** and the **bootstrap source** for the family.

- `conformance/` holds an OPA/Rego policy (`kellerai.oss.conformance`) that expresses the structural
  rules as machine-checkable code. Any repo in the family calls the reusable GitHub Actions workflow
  in `.github/workflows/conformance.yml` to run this policy against itself on every push and pull request.
- `template/` holds tokenized file scaffolds. The `scripts/bootstrap.sh` script stamps a new
  conformant repo from these templates in one command.
- `standard/OSS-PUBLICATION-STANDARD.md` is the canonical prose standard — the single authoritative
  reference that `conformance/data.json` is derived from.

Both halves share a single source of truth (`conformance/data.json`), so what the policy enforces and
what the bootstrap produces can never silently diverge.

## How to use it

### Bootstrap a new repository

```bash
bash scripts/bootstrap.sh \
  --name my-new-repo \
  --artifact-type json-schema \
  --license Apache-2.0 \
  --noun schema \
  --out /path/to/output/my-new-repo
```

`--artifact-type` must be one of: `json-schema`, `markdown-spec`, `rego-policy`, `rag-config`.
`--license` must be one of: `Apache-2.0`, `CC-BY-4.0`, `MIT`.

The script copies `template/_files/`, substitutes tokens, drops the chosen license body, and writes
a `.kellerai-oss.json` marker. It does not `git init` or push — that is your next step.

### Wire the conformance workflow into an existing repository

Add a `conformance` job to your repo's `.github/workflows/ci.yml`:

```yaml
conformance:
  uses: jonathan-kellerai/kellerai-oss-template/.github/workflows/conformance.yml@<sha>
  with:
    artifact_type: json-schema   # match your repo's type
```

Pin to a commit SHA, not a branch name. The `v0.1.0` tag SHA is recorded in
`docs/adoption-guide.md` once the repo is public.

Before the first CI run, generate a snapshot and validate it locally:

```bash
bash scripts/scan-repo-structure.sh --artifact-type json-schema > repo-structure.json
opa eval -d conformance/ -i repo-structure.json 'data.kellerai.oss.conformance.summary'
```

### Run the policy locally

```bash
# Syntax check and test suite
opa check conformance/
opa test conformance/

# Full evaluation against a snapshot
opa eval -d conformance/ -i repo-structure.json \
  'data.kellerai.oss.conformance.violations'
```

`error`-severity violations block CI. `warning`-severity violations are reported but non-blocking.

## Repository layout

```text
README.md  AGENTS.md  CLAUDE.md  CONTRIBUTING.md  SECURITY.md
LICENSE  NOTICE  CHANGELOG.md  CITATION.cff
commitlint.config.js  lefthook.yml  .markdownlint-cli2.yaml  .gitignore

conformance/
  conformance.rego          — OPA/Rego policy (package kellerai.oss.conformance)
  conformance_test.rego     — opa test suite
  data.json                 — single source of truth: required files, dirs, content assertions
  README.md                 — conformance system quick reference
  affects.json              — blast-radius scope manifest
  blast_radius.rego         — blast-radius policy
  blast_radius_test.rego    — blast-radius test suite
  trust_dial.rego           — trust-dial verdict policy
  trust_dial_data.json      — trust-dial configuration data
  trust_dial_test.rego      — trust-dial test suite
  laas/
    laas.rego               — LaaS (Liability-as-a-Service) policy
    laas_test.rego          — LaaS test suite
    data.json               — LaaS manifest
    README.md               — LaaS quick reference

scripts/
  bootstrap.sh              — scaffold a new repo from template/
  scan-repo-structure.sh    — emit repo-structure.json for opa eval
  check-sanitization.sh     — fail if tracked files contain internal-only terms
  pulse.sh                  — blast-radius pulse runner
  publish.sh                — publication helper
  laas/                     — LaaS helper scripts and emitter

template/
  _files/                   — tokenized publishable tree (README, AGENTS, CLAUDE, .github/, etc.)
  licenses/                 — verbatim Apache-2.0.txt, CC-BY-4.0.txt, MIT.txt, NOTICE.tmpl
  manifests/                — .kellerai-oss.json templates per artifact type

standard/
  OSS-PUBLICATION-STANDARD.md   — the prose publication standard (canonical)
  LAAS.md                       — LaaS specification

audit/
  trust-dial-state.json     — current trust-dial tier state
  decision-trace.jsonl      — trust-dial decision audit trail
  blast-radius.jsonl        — blast-radius pulse trace

docs/
  index.md                  — documentation home
  conformance-policy.md     — policy rule reference
  adoption-guide.md         — step-by-step adoption for existing repos
  branch-governance.md      — branch-tier governance rules and escalation paths
  adr/
    ADR-001-trust-dial-dependabot.md
    ADR-002-blast-radius-pulse.md
  laas/                     — LaaS documentation, proposals, and standard renderings
  agents/
    conventions.md          — Conventional Commits, branch naming, PR style (Tier-2)
    citation.md             — how to cite this repo (Apache-2.0, BibTeX, CITATION.cff)
    glossary.md             — load-bearing vocabulary
    enforcement.md          — how these conventions are enforced

.github/
  workflows/
    conformance.yml         — reusable workflow (called by sibling repos)
    ci.yml                  — this repo's own CI
    commitlint.yml
    pages.yml
    trust-dial-gate.yml     — trust-dial gate and outcome workflows
    trust-dial-outcome.yml
    blast-radius-pulse.yml  — blast-radius pulse and outcome workflows
    blast-radius-outcome.yml
    validate-branch-name.yml
    validate-branch-tier.yml
    validate-linked-issue.yml
  ISSUE_TEMPLATE/           — four structured forms (policy-bug, clarification, amendment, integration)
  CODEOWNERS
  dependabot.yml
  PULL_REQUEST_TEMPLATE.md
```

## The four artifact types

| Type | Primary validator | Default artifact dir |
|------|------------------|---------------------|
| `json-schema` | `ajv` | `schemas/` |
| `markdown-spec` | `markdownlint` | `specs/` |
| `rego-policy` | `opa` | `conformance/` |
| `rag-config` | `ajv` | `configs/` |

---

## For agents

Agents reading this repository should start at [AGENTS.md](AGENTS.md), not this README.
Claude Code users: see [CLAUDE.md](CLAUDE.md), which imports `AGENTS.md`.
The agent files document the conventions, file layout, and contribution discipline that agents are expected to follow.
