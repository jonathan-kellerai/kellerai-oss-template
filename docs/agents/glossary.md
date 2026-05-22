# Glossary — kellerai-oss-template

Load-bearing vocabulary for this repository. One entry per term. Definitions
are grounded in `conformance/conformance.rego`, `conformance/data.json`, and
`standard/OSS-PUBLICATION-STANDARD.md`. This is a Tier-2 reference — `AGENTS.md`
points here.

## Artifact type

One of four values that classify a kellerai OSS repo by the kind of artifact it
publishes: `json-schema`, `markdown-spec`, `rego-policy`, `rag-config`. The type
controls the expected artifact directory and the required primary validator in CI.
Declared in `.kellerai-oss.json` and read by `scan-repo-structure.sh`.
Source: `conformance/data.json:45-68`.

## Bootstrap

The act of scaffolding a new conformant repository from `template/_files/` using
`scripts/bootstrap.sh`. The script copies the tokenized template, substitutes
`{{TOKEN}}` placeholders, drops the chosen license body, and writes
`.kellerai-oss.json`. It does not `git init` or push — generation only.
Source: `scripts/bootstrap.sh:1-2`.

## CODEOWNERS lock

The `.github/CODEOWNERS` file routes pull-request review for sensitive paths
(`.github/`, `LICENSE`, `NOTICE`, `AGENTS.md`, `CLAUDE.md`, foundational
artifacts) to `@jonathan-kellerai`. Changes to those paths cannot be merged
without owner approval.
Source: OSS-PUBLICATION-STANDARD.md §9.

## Conformance

A repository *conforms* when `data.kellerai.oss.conformance.allow` is `true` —
i.e. it has zero `error`-severity violations. `warning`-severity violations are
reported but do not affect conformance. Source: `conformance.rego:281-283`.

## Deny set

The OPA set `deny` — the primary output of `conformance.rego`. Each entry
carries `{rule, severity, field, msg}`. The set is produced by partial rule
evaluation; every matching `deny contains entry if { ... }` block contributes
an entry. Source: `conformance.rego:46-264`.

## Policy integrity digest

The SHA-256 hash of `conformance/conformance.rego`, stored in
`data.policy_integrity.expected_digest`. If the live policy hash diverges from
the manifest, the `policy_integrity` rule fires with `error` severity. This
prevents the policy from being silently weakened without the manifest being
updated. The digest is `PENDING` until frozen at release.
Source: `conformance.rego:243-264`, `conformance/data.json:87-90`.

## Reusable workflow

The `.github/workflows/conformance.yml` file in this repo, declared with
`on: workflow_call`. Sibling repos call it from their own `ci.yml` via
`uses: jonathan-kellerai/kellerai-oss-template/.github/workflows/conformance.yml@<SHA>`.
The workflow checks out both the caller's repo and this repo, runs
`scan-repo-structure.sh`, and evaluates the policy. Callers pin to a commit
SHA, not a branch.
Source: plan-how-to-create-peppy-bunny.md §1c.

## Sanitization

The process of removing internal-only terms from the publishable tree before
publication. `scripts/check-sanitization.sh` holds the denylist base64-encoded,
decodes it at runtime, and greps tracked files. It fails the build on any
match. Source: `scripts/check-sanitization.sh`, OSS-PUBLICATION-STANDARD.md §3.

## Sentinel guard

A Rego pattern that distinguishes an absent key from a falsy value.
`_sentinel := {"__absent__": true}` is the guard object; `_get(obj, key)`
returns it when the key is missing; `_present(obj, key)` returns `true` only
when the key genuinely exists. Used to avoid false negatives on optional input
fields. Source: `conformance.rego:36-40`.

## Severity

The `severity` field of a `deny` entry: either `"error"` or `"warning"`.
`error` entries are collected in the `errors` surface rule and block CI when
non-empty. `warning` entries are collected in `warnings` and are reported but
non-blocking. Source: `conformance.rego:275-278`.

## Single source of truth (SSOT)

`conformance/data.json` is the SSOT for what the policy checks and what the
bootstrap scaffold generates. Both `conformance.rego` and `scripts/bootstrap.sh`
read from it. A change to required files or artifact types must be made in
`data.json`; the policy and the bootstrap then reflect it automatically.
Source: `conformance/data.json`, plan §1a.

## Structural drift

The state where sibling repositories diverge from the kellerai OSS structure
standard — missing required files, wrong default branch, absent agent docs, etc.
The conformance policy exists to detect and block drift automatically.

## Tokenized template

A file in `template/_files/` that contains `{{TOKEN}}` placeholders.
`scripts/bootstrap.sh` substitutes them at scaffold time. Tokens include
`{{REPO_NAME}}`, `{{ARTIFACT_TYPE}}`, `{{PRIMARY_VALIDATOR}}`, `{{LICENSE_ID}}`,
`{{OWNER}}`, `{{AUTHOR}}`, `{{YEAR}}`, and others.
Source: `scripts/bootstrap.sh:86-97`.
