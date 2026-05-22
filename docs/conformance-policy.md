# Conformance Policy Catalog

A complete catalog of `conformance/conformance.rego` — every `deny` rule, the
four artifact types, the surface rules, and the `data.json` manifest structure.
The policy package is `kellerai.oss.conformance`.

---

## How the policy works

The policy consumes two inputs:

- **`input`** — a `repo-structure.json` snapshot produced by
  `scripts/scan-repo-structure.sh` (`conformance/README.md:39-42`).
- **`data`** — the manifest `conformance/data.json`, loaded by `opa eval -d conformance/`.

It emits a structured **`deny` set**. Each entry has the shape:

```json
{"rule": "string", "severity": "error|warning", "field": "string", "msg": "string"}
```

`error` entries block CI. `warning` entries are reported but non-blocking.

---

## Surface rules

| Rule | Path | Meaning |
|------|------|---------|
| `violations` | `data.kellerai.oss.conformance.violations` | Every violation — errors and warnings. |
| `errors` | `data.kellerai.oss.conformance.errors` | Error-severity violations only. |
| `warnings` | `data.kellerai.oss.conformance.warnings` | Warning-severity violations only. |
| `allow` | `data.kellerai.oss.conformance.allow` | `true` when there are zero `error` entries. |
| `summary` | `data.kellerai.oss.conformance.summary` | `{allow, total, errors, warnings}` — compact CI output. |

`allow` defaults to `false` (`conformance.rego:281`); it becomes `true` only
when `count(errors) == 0` (`conformance.rego:283`).

---

## deny rules — complete catalog

### `data_sentinel` — error

**Trigger:** `data.schema` is absent; the conformance manifest was not loaded.

**Fix:** run `opa eval -d conformance/ -i repo-structure.json ...` — the `-d`
flag loads `data.json`. Do not pass just the `.rego` file.

**Source:** `conformance.rego:48-56`

---

### `required_file` — error

**Trigger:** A file listed in `data.schema.required_files` is not present in
`input.files`.

**Required files** (from `conformance/data.json:4-18`):

```text
README.md  AGENTS.md  CLAUDE.md  LICENSE  NOTICE  CHANGELOG.md
CITATION.cff  CONTRIBUTING.md  SECURITY.md  .gitignore
.markdownlint-cli2.yaml  commitlint.config.js  lefthook.yml
```

**Fix:** Create the missing file. For content expectations see the relevant
template file in `template/_files/`.

**Source:** `conformance.rego:59-68`

---

### `required_dir` — error

**Trigger:** A directory listed in `data.schema.required_dirs` is absent from
`input.dirs`.

**Required directories** (from `conformance/data.json:19-26`):

```text
.github  .github/workflows  .github/ISSUE_TEMPLATE
docs  docs/agents  scripts
```

**Fix:** Create the directory. At minimum add a `.gitkeep` so it is tracked.

**Source:** `conformance.rego:71-80`

---

### `required_github_file` — error

**Trigger:** A file listed in `data.schema.required_github_files` is missing.

**Required `.github/` files** (from `conformance/data.json:27-35`):

```text
.github/CODEOWNERS
.github/dependabot.yml
.github/PULL_REQUEST_TEMPLATE.md
.github/workflows/ci.yml
.github/workflows/commitlint.yml
.github/workflows/pages.yml
.github/ISSUE_TEMPLATE/config.yml
```

**Fix:** Copy the corresponding template from `template/_files/.github/` and
substitute tokens.

**Source:** `conformance.rego:83-92`

---

### `required_agent_doc` — error

**Trigger:** A file listed in `data.schema.required_agent_docs` is missing.

**Required agent docs** (from `conformance/data.json:36-41`):

```text
docs/agents/conventions.md
docs/agents/citation.md
docs/agents/glossary.md
docs/agents/enforcement.md
```

**Fix:** Create or copy the missing file from the template scaffold.

**Source:** `conformance.rego:95-104`

---

### `required_script` — error

**Trigger:** A file listed in `data.schema.required_scripts` is missing.

**Required scripts** (from `conformance/data.json:42-44`):

```text
scripts/check-sanitization.sh
```

**Fix:** Copy `scripts/check-sanitization.sh` from `kellerai-oss-template` and
populate the repo-specific base64 denylist (see `scripts/check-sanitization.sh:9`
for the regeneration command).

**Source:** `conformance.rego:107-116`

---

### `artifact_type_known` — error

**Trigger:** `input.artifact_type` is not one of the four known values.

**Valid values** (from `conformance/data.json:45-50`):

```text
json-schema  markdown-spec  rego-policy  rag-config
```

**Fix:** Set `artifact_type` in `.kellerai-oss.json` to one of the four values,
or pass `--artifact-type` to `scan-repo-structure.sh`.

**Source:** `conformance.rego:119-127`

---

### `artifact_dir` — error

**Trigger:** The artifact directory for the declared `artifact_type` is absent
from `input.dirs`. The expected directory comes from
`data.schema.artifact_type_files[input.artifact_type].default_dir` unless
overridden by `input.artifact_dir`.

**Default directories by type:**

| `artifact_type` | Default directory | Primary validator |
|-----------------|-------------------|-------------------|
| `json-schema` | `schemas` | `ajv` |
| `markdown-spec` | `specs` | `markdownlint` |
| `rego-policy` | `conformance` | `opa` |
| `rag-config` | `configs` | `ajv` |

**Fix:** Create the artifact directory, or set `artifact_dir` in
`.kellerai-oss.json` if the repo uses a non-default layout.

**Source:** `conformance.rego:129-141`

---

### `agents_md_length` — warning

**Trigger:** `AGENTS.md` line count exceeds `data.content_assertions.agents_md_max_lines`
(150, from `conformance/data.json:79`).

**Fix:** Shorten `AGENTS.md`. Move detail to Tier-2 files under `docs/agents/`.
The standard requires `AGENTS.md` to be ≤ 150 lines (OSS-PUBLICATION-STANDARD.md §1).

**Source:** `conformance.rego:143-153`

---

### `claude_md_length` — warning

**Trigger:** `CLAUDE.md` line count exceeds `data.content_assertions.claude_md_max_lines`
(80, from `conformance/data.json:80`).

**Fix:** Shorten `CLAUDE.md`. Session-specific notes only; agent context belongs
in `AGENTS.md` and `docs/agents/`.

**Source:** `conformance.rego:155-166`

---

### `claude_md_import` — error

**Trigger:** The first non-blank, non-comment line of `CLAUDE.md` is not exactly
`@AGENTS.md` (from `conformance/data.json:81`).

**Fix:** Make `@AGENTS.md` the first content line of `CLAUDE.md`. Comments and
blank lines before the import are permitted.

**Source:** `conformance.rego:168-179`

---

### `readme_agent_footer` — warning

**Trigger:** The last 15 lines of `README.md` do not contain the string `For agents`
(from `conformance/data.json:82`).

**Fix:** Add a short "For agents" section near the bottom of `README.md` pointing
at `AGENTS.md`. See `template/_files/README.md` for the canonical form.

**Source:** `conformance.rego:182-193`

---

### `gitignore_coverage` — error

**Trigger:** `.gitignore` is missing one or more required patterns listed in
`data.schema.gitignore_required_patterns` (from `conformance/data.json:72-76`):

```text
.claude/
.claude-tmp/
.DS_Store
```

**Fix:** Add the missing patterns to `.gitignore`. These keep staging-session
artifacts and macOS noise out of the published tree.

**Source:** `conformance.rego:195-207`

---

### `forbidden_branch` — error

**Trigger:** `input.branches` contains a branch name listed in
`data.schema.forbidden_branches` (from `conformance/data.json:69-71`).
Currently `master` is the only forbidden branch.

**Fix:** Delete the `master` branch and ensure the default branch is `main`.
`git branch -m master main` if renaming; `gh repo edit --default-branch main`
on GitHub.

**Source:** `conformance.rego:209-218`

---

### `primary_validator_wired` — warning

**Trigger:** No line in any `.github/workflows/*.yml` file references the
`primary_validator` string for the declared `artifact_type`. For example, a
`json-schema` repo must have a workflow line containing `ajv`; a `rego-policy`
repo must reference `opa`.

**Fix:** Add the artifact validation step to `.github/workflows/ci.yml`.
See `docs/adoption-guide.md` for the recommended CI structure.

**Source:** `conformance.rego:221-232`

---

### `policy_integrity` — error

**Trigger:** `input.policy_digest` (the SHA-256 of the live `conformance.rego`)
does not match `data.policy_integrity.expected_digest` AND `expected_digest` is
not `"PENDING"` AND `input.policy_digest` is non-empty.

This rule fires only when the scanning repo has a vendored copy of the policy
(i.e. `kellerai-oss-template` scanning itself). Consumer repos that call the
centralized workflow have no vendored policy, so `input.policy_digest` is empty
and the check is skipped.

**Fix:** `conformance.rego` was modified without updating
`data.policy_integrity.expected_digest`. Recompute:
`sha256sum conformance/conformance.rego` and write the hex digest into
`data.json` at `policy_integrity.expected_digest`. Run
`scripts/scan-repo-structure.sh` and `opa eval` to confirm the rule is clear.

**Source:** `conformance.rego:243-254`

---

### `policy_integrity_manifest` — error

**Trigger:** `data.policy_integrity.expected_digest` key is absent from
`data.json`.

**Fix:** The integrity manifest field was deleted. Restore it — even setting it
to `"PENDING"` satisfies this rule. See `conformance/data.json:87-90` for the
correct structure.

**Source:** `conformance.rego:256-264`

---

## The four artifact types

Each kellerai OSS repo declares exactly one `artifact_type` in
`.kellerai-oss.json`. The type controls which directory the policy expects to
find artifacts in and which primary validator must be wired into CI.

| `artifact_type` | Purpose | Default artifact dir | Primary validator |
|-----------------|---------|----------------------|-------------------|
| `json-schema` | JSON Schema definitions | `schemas/` | `ajv` |
| `markdown-spec` | Specification documents | `specs/` | `markdownlint` |
| `rego-policy` | OPA/Rego policy files | `conformance/` | `opa` |
| `rag-config` | RAG pipeline configuration | `configs/` | `ajv` |

Source: `conformance/data.json:51-68`.

---

## The `data.json` manifest — structure overview

`conformance/data.json` is the **single source of truth** for what the policy
checks. Both the policy and `scripts/bootstrap.sh` read from it, so "what we
enforce" and "what we scaffold" cannot diverge.

| Key | Type | Purpose |
|-----|------|---------|
| `schema.required_files` | array of strings | Files every repo must have. |
| `schema.required_dirs` | array of strings | Directories every repo must have. |
| `schema.required_github_files` | array of strings | `.github/` files every repo must have. |
| `schema.required_agent_docs` | array of strings | Tier-2 agent doc files. |
| `schema.required_scripts` | array of strings | Utility scripts every repo must ship. |
| `schema.artifact_types` | array of strings | Enum of valid `artifact_type` values. |
| `schema.artifact_type_files` | object | Per-type default directory and primary validator. |
| `schema.forbidden_branches` | array of strings | Branch names the policy rejects. |
| `schema.gitignore_required_patterns` | array of strings | Patterns `.gitignore` must contain. |
| `content_assertions` | object | Line caps and first-line requirements for `AGENTS.md`, `CLAUDE.md`, `README.md`. |
| `policy_integrity` | object | `{algorithm, expected_digest}` — the SHA-256 self-integrity check. |
