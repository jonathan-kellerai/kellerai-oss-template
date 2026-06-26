# conformance/

The OPA/Rego policy that checks a repository's file and directory structure
against the kellerai OSS publication standard. It is the machine-checkable half
of this repo — `template/` is the bootstrap half, and both are driven from the
same source of truth, `data.json`.

## Files

- **`data.json`** — the single source of truth. Lists required files,
  directories, `.github/` files, agent docs and scripts; the four artifact
  types and their primary validators; forbidden branches; required `.gitignore`
  patterns; content assertions; and the policy self-integrity digest.
- **`conformance.rego`** — package `kellerai.oss.conformance`. Consumes a
  `repo-structure.json` snapshot as `input` and `data.json` as `data`, and emits
  a structured `deny` set.
- **`conformance_test.rego`** — the `opa test` suite for `conformance.rego`.
- **`affects.json`** — dependency-impact manifest; maps source paths to the
  downstream conformance rules they affect, used by tooling to scope re-checks.
- **`trust_dial.rego`** — package `kellerai.oss.trust_dial`. Evaluates a repo's
  trust level (CT1–CT5) from its conformance profile.
- **`trust_dial_data.json`** — threshold table and weight configuration consumed
  by `trust_dial.rego`.
- **`trust_dial_test.rego`** — the `opa test` suite for `trust_dial.rego`.
- **`blast_radius.rego`** — package `kellerai.oss.blast_radius`. Computes a
  change-blast-radius pulse score from a repo snapshot.
- **`blast_radius_test.rego`** — the `opa test` suite for `blast_radius.rego`.
- **`laas/`** — Liability-as-a-Service sub-policy. Contains:
  - **`laas/laas.rego`** — package `kellerai.oss.laas`. Evaluates liability
    exposure from conformance violations.
  - **`laas/data.json`** — scoring weights and threshold configuration consumed
    by `laas.rego`.
  - **`laas/laas_test.rego`** — the `opa test` suite for `laas.rego`.
  - **`laas/README.md`** — prose overview of the LaaS sub-policy.
  - **`laas/examples/action.ct4-blocked.json`** — example input fixture showing
    a CT4-blocked action evaluation.

## Violation shape

Each `deny` entry is `{"rule", "severity", "field", "msg"}`. `severity` is
`error` (blocks CI) or `warning` (reported, non-blocking).

| Surface rule | Meaning |
|--------------|---------|
| `data.kellerai.oss.conformance.violations` | every violation |
| `data.kellerai.oss.conformance.errors` | error-severity only |
| `data.kellerai.oss.conformance.warnings` | warning-severity only |
| `data.kellerai.oss.conformance.allow` | `true` when there are zero errors |
| `data.kellerai.oss.conformance.summary` | `{allow, total, errors, warnings}` |

## Running it

```bash
# Syntax + type check, and the test suite
opa check conformance/conformance.rego
opa test conformance/

# Evaluate against a repo snapshot (see scripts/scan-repo-structure.sh)
opa eval -d conformance/ -i repo-structure.json \
  'data.kellerai.oss.conformance.summary'
```

## Self-integrity

`data.json` carries `policy_integrity.expected_digest` — the SHA-256 of
`conformance.rego`. The `policy_integrity` rule fires if the live policy digest
diverges from the manifest, so the policy cannot be silently weakened without
the digest being refrozen. A second rule (`policy_integrity_manifest`) fires if
the digest field is removed entirely. The digest is `PENDING` until frozen by
the release-hardening step.
