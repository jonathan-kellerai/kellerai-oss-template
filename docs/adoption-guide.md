# Adoption Guide

How a sibling repo adopts the kellerai OSS conformance workflow — from zero to
a passing CI gate in four steps.

---

## Prerequisites

- `opa` CLI installed (`brew install opa` or the GitHub releases page).
- Node.js available if you want `ajv-cli` for JSON-Schema repos.
- The sibling repo is already a git repository on branch `main`.

---

## Step 1 — Add the `.kellerai-oss.json` marker

Create `.kellerai-oss.json` at the repo root. This file tells
`scan-repo-structure.sh` what kind of repo it is.

```json
{
  "artifact_type": "<one of: json-schema | markdown-spec | rego-policy | rag-config>",
  "artifact_dir": "<your artifact directory, if non-default>",
  "primary_validator": "<ajv | markdownlint | opa>",
  "owner": "jonathan-kellerai"
}
```

**`artifact_type` controls two things** in the conformance policy:

1. Which directory is expected to contain your artifacts
   (`schemas/`, `specs/`, `conformance/`, or `configs/`).
2. Which primary validator must appear in your CI workflow.

If your artifact directory matches the default for your type (see the table in
`docs/conformance-policy.md`), you may omit `artifact_dir`. The field is used
by `scan-repo-structure.sh` if present; otherwise the policy's `default_dir`
applies.

Commit this file:

```bash
git add .kellerai-oss.json
git commit -m "chore: add kellerai-oss conformance marker"
```

---

## Step 2 — Add the required structure

The policy enforces a required set of files, directories, and `.github/` files.
Run a local check first (Step 4) to see what is missing, then fill the gaps
using the template scaffold:

```bash
# Clone kellerai-oss-template (read-only; you are not bootstrapping a fresh repo)
git clone https://github.com/jonathan-kellerai/kellerai-oss-template /tmp/oss-tmpl

# Copy any missing .github/ files
cp /tmp/oss-tmpl/template/_files/.github/... .github/

# Copy the sanitization script
cp /tmp/oss-tmpl/scripts/check-sanitization.sh scripts/
# Then populate the base64 denylist with your repo's internal terms:
#   printf 'term-one\nterm-two\n' | base64
# Edit the DENYLIST_B64 variable in scripts/check-sanitization.sh.
```

Minimum required structure — see `docs/conformance-policy.md` for the full list.
At a minimum you need:

```
README.md  AGENTS.md  CLAUDE.md  LICENSE  NOTICE  CHANGELOG.md
CITATION.cff  CONTRIBUTING.md  SECURITY.md  .gitignore
.markdownlint-cli2.yaml  commitlint.config.js  lefthook.yml
.github/CODEOWNERS  .github/dependabot.yml
.github/PULL_REQUEST_TEMPLATE.md
.github/ISSUE_TEMPLATE/config.yml
.github/workflows/ci.yml
.github/workflows/commitlint.yml
.github/workflows/pages.yml
docs/agents/conventions.md  docs/agents/citation.md
docs/agents/glossary.md     docs/agents/enforcement.md
scripts/check-sanitization.sh
```

---

## Step 3 — Wire the conformance job into CI

Add a `conformance` job to your `.github/workflows/ci.yml` that calls the
reusable workflow. Pin to a commit SHA — never a floating tag or branch ref.

```yaml
jobs:
  conformance:
    uses: jonathan-kellerai/kellerai-oss-template/.github/workflows/conformance.yml@<PENDING-SHA>
    with:
      artifact_type: json-schema   # substitute your artifact_type
```

The placeholder `<PENDING-SHA>` is the commit SHA of the `v0.1.0` release of
`kellerai-oss-template`. It will be filled when the template repo is tagged and
made public. **Do not use a branch name here** — reusable-workflow callers must
pin to a SHA or tag per the OSS publication standard (OSS-PUBLICATION-STANDARD.md §2).

**Why a SHA?** The conformance workflow checks out both your repo and
`kellerai-oss-template` (to get the policy and scanner). Pinning to a SHA means
a policy update in the template does not silently change your CI behaviour.

The reusable workflow does the following on every call:

1. Checks out your repo with `fetch-depth: 0` (branch enumeration requires history).
2. Checks out `kellerai-oss-template` at the pinned SHA into a subpath.
3. Installs OPA via `open-policy-agent/setup-opa@v2.4.0`.
4. Runs `scripts/scan-repo-structure.sh` to produce `repo-structure.json`.
5. Runs `opa check conformance/` (syntax and type check).
6. Runs `opa eval -d conformance/ -i repo-structure.json 'data.kellerai.oss.conformance.violations'`.
7. Fails the job if any `error`-severity violation is present; prints a formatted
   table of all violations.

---

## Step 4 — Run the check locally

You do not need to push to GitHub to check conformance. Run the scanner and the
policy evaluator locally:

```bash
# From your sibling repo root.
# Assumes you have kellerai-oss-template cloned somewhere, e.g. /tmp/oss-tmpl.

# 1. Generate the repo snapshot.
bash /tmp/oss-tmpl/scripts/scan-repo-structure.sh > repo-structure.json

# 2. Syntax check the policy.
opa check /tmp/oss-tmpl/conformance/

# 3. Evaluate — inspect the summary.
opa eval \
  -d /tmp/oss-tmpl/conformance/ \
  -i repo-structure.json \
  'data.kellerai.oss.conformance.summary'

# 4. See every violation with its rule id, severity, and message.
opa eval \
  -d /tmp/oss-tmpl/conformance/ \
  -i repo-structure.json \
  'data.kellerai.oss.conformance.violations'
```

A clean repo returns:

```json
[{"result": {"allow": true, "errors": 0, "total": 0, "warnings": 0}}]
```

Any `error`-severity violations must be resolved before the CI gate will pass.
`warning`-severity violations are reported but do not block the job.

---

## Troubleshooting

**`unknown artifact_type`** — `.kellerai-oss.json` has a typo or the file is
absent. Valid values: `json-schema`, `markdown-spec`, `rego-policy`, `rag-config`.

**`artifact directory missing`** — Create the artifact directory or set
`artifact_dir` in `.kellerai-oss.json`.

**`conformance manifest not loaded`** — You passed only the `.rego` file to
`opa eval`. Use `-d conformance/` to load the whole directory (both
`conformance.rego` and `data.json`).

**`forbidden branch present: master`** — Delete or rename the `master` branch.

**`no CI workflow references the primary validator`** — Add the validation step
for your artifact type to `.github/workflows/ci.yml`.

**`CLAUDE.md first content line is not @AGENTS.md`** — The first non-blank,
non-comment line in `CLAUDE.md` must be exactly `@AGENTS.md`.
