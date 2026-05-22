# Enforcement — kellerai-oss-template

Tier-2 detail for `AGENTS.md`. How conformance is enforced going forward —
what is automated, what is gated by review, and what is self-protecting.

## The CI gate

The `.github/workflows/conformance.yml` reusable workflow is the primary
enforcement mechanism. It runs on every `push` and `pull_request` and fails
the build if any `error`-severity violation is present.

The workflow evaluates `data.kellerai.oss.conformance.violations` and formats
the output as a table. `error` entries cause a non-zero exit code. `warning`
entries are printed but do not fail the job.

Sibling repos call the workflow via `uses:` pinned to a commit SHA. This means
a policy change in `kellerai-oss-template` only takes effect in a sibling repo
when the sibling explicitly bumps the SHA — preventing silent policy upgrades.

## Error vs warning severity

| Severity | Blocks CI? | Examples |
|----------|-----------|---------|
| `error` | Yes | Missing required file, unknown artifact type, forbidden `master` branch, bad `.gitignore`, policy digest mismatch, missing `@AGENTS.md` import. |
| `warning` | No | `AGENTS.md` too long, `CLAUDE.md` too long, missing README agent footer, primary validator not wired into CI. |

The full catalog with fix instructions is in `docs/conformance-policy.md`.

## Policy self-integrity digest

`conformance/data.json` carries `policy_integrity.expected_digest` — the
SHA-256 of `conformance/conformance.rego`. The `policy_integrity` rule in the
policy fires if the live digest diverges from the manifest value, so the policy
cannot be silently weakened.

When you modify `conformance.rego`, you must refreeze the digest:

```bash
sha256sum conformance/conformance.rego   # Linux
shasum -a 256 conformance/conformance.rego  # macOS
# Write the hex digest into data.json at policy_integrity.expected_digest
```

A companion CI step recomputes and asserts the digest on every push to this
repo, so a digest mismatch is caught before any consumer is affected.

The `policy_integrity_manifest` rule fires if the `expected_digest` key is
removed from `data.json` entirely — closing the bypass of deleting the field.
Source: `conformance.rego:256-264`.

## CODEOWNERS lock

`.github/CODEOWNERS` routes pull-request review for policy-sensitive paths to
`@jonathan-kellerai`. The locked paths are:

```text
.github/
LICENSE
NOTICE
AGENTS.md
CLAUDE.md
conformance/
```

Changes to these paths require owner approval before merging. This prevents an
unreviewed PR from weakening the policy or bypassing the digest guard.

## Pre-commit hook

`lefthook.yml` defines a pre-commit hook that contributors install via
`lefthook install`. It runs two checks before every commit:

1. `scripts/check-sanitization.sh` — ensures no internal term from the denylist
   appears in the staged tree.
2. The primary artifact validation for this repo's type (`opa check
   conformance/` for `rego-policy` repos).

The hook is a convenience — it gives local fast feedback. CI runs the same
gates, so the hook is not the sole line of defence.

## Where a convention lives

`AGENTS.md` and `docs/agents/` are canonical. When a convention changes:

1. Update `docs/agents/conventions.md` (or the relevant Tier-2 file) first.
2. Update the `AGENTS.md` summary if the Tier-1 overview is now stale.
3. Propagate to `CONTRIBUTING.md` and `README.md` if either restates it.

`README.md` and `CONTRIBUTING.md` are downstream of `docs/agents/`. A reviewer
who sees a convention stated in `README.md` but not in `docs/agents/` should
treat `docs/agents/` as authoritative and flag the discrepancy.
