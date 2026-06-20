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

### Workflow change history

| Date | Classification | Description |
|------|---------------|-------------|
| 2026-06-09 | non-breaking | Refreshed internal third-party action SHA pins across all workflow files. In `conformance.yml` and `ci.yml`: `actions/checkout` → `df4cb1c069e1874edd31b4311f1884172cec0e10` (v6.0.3); `open-policy-agent/setup-opa` → `b2b258e089860efaadaaf71bf6e3aecb4a3eeff1` (v2.4.0). In `trust-dial-gate.yml`: `dependabot/fetch-metadata` → `08eff52bf64351f401fb50d4972fa95b9f2c2d1b` (v2.4.0); `actions/upload-artifact` → `043fb46d1a93c77aae656e7c1c64a875d1fc6a0a` (v7.0.1). The `workflow_call` interface (inputs `artifact_type` and `opa_version`, outputs, and all consumer-visible steps) is **unchanged** — only internal `uses:` pins moved. No consumer migration is required and no major version bump is warranted; consumers pick up the refreshed pins automatically when they next bump the kellerai-oss-template SHA they pin to. Source: `.github/workflows/conformance.yml:44,55,86`, `.github/workflows/ci.yml:24,27`, `.github/workflows/trust-dial-gate.yml:36,37,184`. |
| 2026-06-09 | deferred | `dependabot/fetch-metadata` v3 major bump deliberately deferred (PR #14). v3 renames the metadata outputs (`update-type`, `package-ecosystem`, etc.) that `trust-dial-gate.yml` consumes at lines 46–50; adopting it requires coordinated changes to the gate workflow and the OPA input-builder step. |

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

## The trust-dial policy

`conformance/trust_dial.rego` is a second OPA policy that lives next to the
structural `conformance.rego`.
It governs Dependabot auto-merge decisions and is a **pure function** over
three inputs:
a Dependabot PR descriptor (`input`), the verdict matrix (`data.trust_dial.verdict_matrix`),
and the per-cycle budget (`data.trust_dial.budget`).

- **Package:** `kellerai.oss.trust_dial`.
- **Sibling data:** `conformance/trust_dial_data.json` carries the
  `(tier × ecosystem × update_type)` verdict matrix plus the
  `max_auto_merges_per_cycle` budget.
- **Sibling tests:** `conformance/trust_dial_test.rego` exercises every cell in
  the matrix plus the fail-safe default; `opa test conformance/` proves the
  policy is deterministic.
- **Surfaces:** `verdict` (one of `"auto-merge"`, `"hold-for-review"`,
  `"block"`), `rationale` (a single string written verbatim into the decision
  trace), and `decision` (the full record carrying the four whitepaper fields:
  `inputs`, `rule_applied`, `alternatives`, `rationale`).
- **Fail-safe default:** `verdict := "hold-for-review"`.
  The policy never auto-merges by omission — the matrix must explicitly opt in.
- **Budget gate:** an `auto-merge` base verdict downgrades to
  `hold-for-review` once the cycle budget is exhausted
  (`input.cycle_merge_count >= _budget.max_auto_merges_per_cycle`).

### `trust_dial_wired` deny family

The structural policy (`conformance/conformance.rego:246-257`) carries a
companion deny family that fires when the trust-dial gate workflow exists in
the repo but no CI step actually evaluates the policy.

- **Rule name:** `trust_dial_wired`.
- **Severity:** `error` (blocks CI).
- **Trigger:** `data.trust_dial_manifest.gate_workflow` is set, that workflow
  file is present in `input.files`, and no line in `input.ci_uses` contains
  the string `data.kellerai.oss.trust_dial`.
- **Intent:** prevent a repo from merely *containing* the gate workflow
  without wiring it — the workflow file must be referenced from a real CI
  step that evaluates the verdict policy.
  This closes the bypass of "the file exists, looks like enforcement, but
  nothing runs it."

### Audit trail — `audit/decision-trace.jsonl`

Every trust-dial decision is appended to `audit/decision-trace.jsonl`
(JSON-Lines, one record per line, append-only).
Each record is the full `decision` surface from the policy plus a timestamp
and the Dependabot PR id.
The file is intentionally append-only so that a tamper attempt is visible in
the next commit's diff.
GitHub Actions also publishes the same record as a per-run artifact, giving
the auditor two redundant copies.

## The LaaS action-conformance policy

`conformance/laas/laas.rego` is the fourth OPA policy (package
`kellerai.laas.actions`, declared at `laas.rego:18`).
It gates individual LLM-agent *actions* by consequence tier — not the model
itself — and applies wherever an agent can take an action with an effect
outside its sandbox.
The gate, not the agent, supplies the observed effect surface; this policy
checks that the tier assignment, verification, and enforcement are correct.

- **Package:** `kellerai.laas.actions` (`laas.rego:18`).
- **Sibling data:** `conformance/laas/data.json` carries the obligation
  registry, the CT lattice, and enforcement thresholds (`data.json:1–34`).
- **Entry points:** `violations` (set of `{obligation, severity, msg}`),
  `summary` (`expected_ct`, `effective_ct`, `errors`, `warnings`, `compliant`),
  and `compliant` (bool — true when no error-severity violations exist)
  (`laas.rego:11–13`).
- **CT classification** — tier is the lattice max of three axes; an unknown
  or undetermined surface defaults to CT4 (`laas.rego:29`; `data.json:11`):
  - **CT0** — no external effect; read-only or fully sandboxed (`laas.rego:32–34`).
  - **CT1** — reversible, single-system internal write
    (reversibility rank 1, scope rank 1; `data.json:7–9`).
  - **CT2** — reversible or low-consequence external effect.
  - **CT3** — hard-to-reverse or material-consequence action; triggers
    independent pre-commit verification (`data.json:12`).
  - **CT4** — irreversible or high-consequence; requires independent
    verification **plus** human approval; default when surface is undetermined
    (`data.json:13`).
- **Effective tier:** max of the gate-assigned CT and the cumulative
  window CT, preventing structuring attacks (`laas.rego:47–49`).
- **Fail-safe default:** `default expected_ct := 4` (`laas.rego:29`).

### LaaS obligation families

Each obligation maps to a violation rule in `laas.rego`; severities are
recorded in `data.json:20–32`.

- **`LAAS-OBL-TIER-001`** — CT is gate-derived from the observed effect
  surface; a gate-assigned tier below the lattice-derived tier is an error
  (`laas.rego:97–103`; `data.json:20`).
- **`LAAS-OBL-SELF-001`** — a self-reported tier may not lower the
  gate-derived tier; the gate always prevails (warning, `laas.rego:105–111`;
  `data.json:21`).
- **`LAAS-OBL-ENF-001`** — enforcement-plane integrity: the policy bundle
  must be signed and the gate must run out-of-process (`laas.rego:113–122`;
  `data.json:22`).
- **`LAAS-OBL-TRC-001`** — the decision trace must be append-only and
  chained (`laas.rego:124–127`; `data.json:23`).
- **`LAAS-OBL-AGG-001`** — the assigned tier must not be below the
  cumulative window CT; guards against structuring (`laas.rego:129–135`;
  `data.json:24`).
- **`LAAS-OBL-INP-001`** — untrusted input must raise the tier to the
  configured floor (CT≥3 by default) or the action must be blocked
  (`laas.rego:137–145`; `data.json:18,25`).
- **`LAAS-OBL-VEN-001`** — third-party or vendor dependencies require
  attribution and scope limits (`laas.rego:147–151`; `data.json:26`).
- **`LAAS-OBL-IRR-001`** — CT≥3 actions require a passing independent
  pre-commit verifier unless the action is blocked (`laas.rego:153–158`;
  `data.json:27`).
- **`LAAS-OBL-IND-001`** — the pre-commit verifier must be independent:
  a distinct checker type, different model lineage, and error-correlation
  ≤ 0.2 (`laas.rego:160–166`; `data.json:14,28`).
- **`LAAS-OBL-VQ-001`** — the verifier must be qualified (DO-330 analogue)
  (`laas.rego:168–174`; `data.json:29`).
- **`LAAS-OBL-RES-001`** — the Bucket-B residual escape rate must be within
  tolerance for the effective tier (`laas.rego:183–192`; `data.json:15,30`).
- **`LAAS-OBL-HUM-001`** — CT4 actions require human approval unless the
  action is blocked (`laas.rego:176–181`; `data.json:13,31`).

### Audit trail — `violations` and `summary`

Every evaluation produces a `summary` record (`laas.rego:214–221`) containing
`bundle`, `expected_ct`, `effective_ct`, `errors`, `warnings`, and `compliant`.
The `violations` set carries the full obligation ID, severity, and a
diagnostic message for each firing rule.
These surfaces are the canonical inputs to any downstream decision log or
append-only trace required by `LAAS-OBL-TRC-001`.

## The blast-radius pulse

`conformance/blast_radius.rego` is the third OPA policy: a deterministic
function that computes the blast radius of a candidate change set.
It enforces the cross-file invariants the structural policy cannot express on
its own.

- **Package:** `kellerai.oss.blast_radius`.
- **Sibling data:** `conformance/affects.json` declares one entry per
  blast-radius rule (`BR-001` through `BR-013` at the time of writing).
  Each entry carries a `when_changed` glob, an `affects` glob list, a list of
  `required_actions`, a `severity` (`error` or `warning`), and a
  `verifiable` flag (see below).
- **Sibling tests:** `conformance/blast_radius_test.rego` exercises every
  entry plus the verifiable/unverifiable split plus the determinism property.
- **Surfaces:** `fired` (the set of entries whose `when_changed` matched a
  path in the diff), `errors` / `warnings` (aggregate counts under the
  verifiable split), `verdict` (one of `"clear"`, `"owed"`, `"blocked"`),
  `allow` (boolean — true when verdict is not `"blocked"`), and `result` (the
  full record carrying the four whitepaper fields).

### The verifiable / unverifiable split

The `verifiable` field on each `affects.json` entry distinguishes a
**machine-checkable post-condition** (`verifiable: true`) from an
**advisory checklist** (`verifiable: false`).
The verdict logic at `conformance/blast_radius.rego:163-202` is:

- An entry counts as an **error** only when it is *both*
  `severity == "error"` *and* `verifiable == true` *and* has owed actions.
  Only such entries trigger a `blocked` verdict.
- Every other fired entry with owed actions counts as a **warning**:
  warning-severity entries, *and* error-severity entries whose actions are
  advisory (`verifiable: false`).
- `verdict == "blocked"` iff `errors > 0`;
  `verdict == "owed"` iff `errors == 0 ∧ warnings > 0`;
  `verdict == "clear"` iff nothing is owed.

This keeps the gate honest:
a `blocked` verdict always corresponds to a deterministic post-condition the
pulse (or the CI step) can verify, never to a footer ack the author may have
typed but not actually performed.
Advisory rules stay surfaced as warnings so the author still sees them,
but they cannot block on the strength of a missing footer alone.

The current per-entry classification:

| Entry | Severity | Verifiable | Why |
|-------|----------|------------|-----|
| `BR-001-conformance-rego` | error | true | The SHA-256 digest match against `data.policy_integrity.expected_digest` is deterministic and re-runnable. |
| `BR-002-artifact-types-triplicate` | error | false | The triplicate parity is implicit — no explicit post-condition exists yet. |
| `BR-003-required-files` | error | false | A new required-file is only validated by running the bootstrap smoke test. |
| `BR-004-agents-md` | warning | true | `wc -l AGENTS.md` against the configured cap is deterministic. |
| `BR-005-claude-md` | error | true | Line count and first-content-line are both deterministic OPA assertions already in the structural policy. |
| `BR-006-new-rego-policy` | error | false | OPA coverage parsing is fragile; the test-existence check is advisory. |
| `BR-007-trust-dial-manifest` | error | false | The mirror validity between the canonical policy and the templatized mirror is implicit — no programmatic equality check yet. |
| `BR-008-templatized-required-file` | warning | false | Requires a bootstrap smoke test. |
| `BR-009-conformance-workflow` | warning | false | The workflow-contract change is implicit (no schema for the contract). |
| `BR-010-scripts-coverage` | warning | true | A grep of `docs/agents/enforcement.md` for the changed script's name is deterministic. |
| `BR-011-affects-manifest` | error | true | Test-coverage for the new manifest entry is grep-able. |
| `BR-012-docs-agents-coverage` | warning | false | Tier-2 prose changes have no deterministic post-condition. |
| `BR-013-template-coverage` | warning | false | Templatized-scaffold reachability requires a bootstrap self-check. |
| `BR-014-laas-conformance-policy` | error | false | OPA coverage parsing is fragile; the test-existence check is advisory. The LaaS policy (`conformance/laas/laas.rego`, package `kellerai.laas.actions`) is a sibling to `conformance.rego`; like BR-006 a new policy must ship a sibling `laas_test.rego` and be documented. Data-driven obligations (`conformance/laas/data.json`), README (`conformance/laas/README.md`), and the worked CT4-blocked example (`conformance/laas/examples/action.ct4-blocked.json`) must stay consistent with the policy; documentation coverage in `docs/agents/enforcement.md` is also owed. |

Adding a new entry to `affects.json` requires the author to make the
verifiable classification explicit.
The default (missing field) is `false` — i.e. opt in by writing
`"verifiable": true` only when a deterministic post-condition exists.

### `affects_manifest_complete` deny family

The structural policy (`conformance/conformance.rego:299-313`) carries a
companion deny family that fires when a file under the **pulse scope** is not
reachable from any `affects.json` entry.

- **Rule name:** `affects_manifest_complete`.
- **Severity:** `error` (blocks CI).
- **Trigger:** a path in `input.files` falls under one of the pulse-scope
  prefixes (`conformance/`, `template/`, `scripts/`, `docs/agents/`), the
  affects manifest is non-empty, and the path is not reachable from any
  entry's `when_changed` glob or `affects` glob.
- **Intent:** an unreachable file is a silent gap — the pulse is only honest
  when the manifest is complete.
  This rule guarantees that every tracked file in the pulse scope has at
  least one manifest entry it can fire against.

### Audit trail — `audit/blast-radius.jsonl`

Every pulse run that produces a non-`"clear"` verdict appends a record to
`audit/blast-radius.jsonl` (JSON-Lines, one record per line, append-only).
The record carries the full `result` structure plus the git SHA at the time
of the run plus the mode (`live`, `audit`, or `predict`).
As with the trust-dial trace, the file is append-only so tamper attempts are
visible in the diff, and GitHub Actions publishes the per-run `verdict.json`,
`pr-comment.md`, and `opa-input.json` as workflow artifacts for redundancy.

### Invoking the pulse — `scripts/pulse.sh`

`scripts/pulse.sh` is the lefthook + CI entry point.
It wraps `opa eval data.kellerai.oss.blast_radius.result` with the same
preflight discipline as `scripts/bootstrap.sh`.

| Mode | Invocation | Reads diff from |
|------|------------|-----------------|
| `live` (default) | `bash scripts/pulse.sh` | `git diff --name-only --cached` |
| `audit` | `bash scripts/pulse.sh --mode audit --diff-range origin/main...HEAD` | the given range |
| `predict` | `bash scripts/pulse.sh --predict path1 path2` | the explicit positional file list |

Exit codes:

- `0` — verdict is `clear` or `owed` (warnings only or no fire).
- `1` — verdict is `blocked` (at least one verifiable=true error has owed actions).
- `2` — `opa eval` failed, manifest invalid, or preflight check failed.

Outputs (written under `--output-dir`, default cwd):

- `opa-input.json` — the exact input passed to `opa eval`.
- `opa-eval.stdout` / `opa-eval.stderr` — the raw OPA output.
- `verdict.json` — the parsed `result` record.
- `pulse-report.txt` — the human-readable report (audit mode only).
- `pr-comment.md` — the PR-comment-ready Markdown report (audit mode only).

### The `Pulse-Action:` commit footer

Owed actions clear in two ways:

1. **The diff already touched the affected file.** The pulse engine already
   sees this through `affected_present_in_diff` — no footer is required.
2. **The author asserts an action is done.** The author appends a line to the
   commit message in the form:

   ```text
   Pulse-Action: BR-001-conformance-rego-1 DONE
   Pulse-Action: BR-001-conformance-rego-2 DONE
   ```

   The id is the entry id plus a 1-based action index.
   `scripts/pulse.sh` parses these lines from the commit-message file passed
   via `--commit-msg-file` and feeds them into the policy as
   `input.commit_footer_actions_done`.
   The policy then decrements `owed_count` for each acked action.

The footer convention applies only to entries with `verifiable: false`, where
no programmatic check exists.
For `verifiable: true` entries the structural policy or a dedicated CI step
re-verifies the post-condition independently — the footer is informational
only, never the sole source of truth.
