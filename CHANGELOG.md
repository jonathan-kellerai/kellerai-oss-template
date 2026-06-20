# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [3.2.0] - 2026-06-20

### Added

- LaaS v1.1 action-conformance policy: `conformance/laas/laas.rego` (package
  `kellerai.laas.actions`) with `conformance/laas/laas_test.rego`, gating
  individual LLM-agent actions by consequence tier (CT0–CT4) rather than
  certifying the model at enrollment time.
- Data-driven obligation registry and CT lattice in `conformance/laas/data.json`;
  worked CT4-blocked example in
  `conformance/laas/examples/action.ct4-blocked.json`.
- Decision-record emitter and backtest harness under `scripts/laas/`:
  `emitter.py`, `backtest.py`, and `check.sh`.
- Blast-radius manifest entry `BR-014-laas-conformance-policy` in
  `conformance/affects.json` plus its sibling test in
  `conformance/blast_radius_test.rego`.
- Standard prose `standard/LAAS.md`, usage docs under `docs/laas/`, and a
  policy section in `docs/agents/enforcement.md`.

### Changed

- CI: bump 7 GitHub Actions to their latest SHA-pinned versions (actions/checkout v6.0.3, download-artifact v8.0.1, upload-artifact v7.0.1, configure-pages v6, upload-pages-artifact v5, deploy-pages v5, github-script v9); pin dependabot/fetch-metadata to a commit SHA at v2.4.0 (was tag-floating). Deferred fetch-metadata v3 (major; renames outputs the trust-dial gate consumes).
- `.github/workflows/commitlint.yml`: also skip commit-message validation on `sync/*` branches
  (not just head==`main`), so `main→dev` syncs done via a conflict-resolution branch don't trip
  on grandfathered commits.
- `.github/dependabot.yml`: route Dependabot PRs to `dev` (`target-branch: dev`)
  instead of the default `main`. Bots now enter the 4-tier branch model at the
  lowest tier and cascade `dev -> qa -> main`, matching external contributors.
- `.github/workflows/validate-branch-tier.yml`: allow `dependabot[bot]` (and
  `dependabot/**` branches) to open PRs into `dev`, alongside the existing
  CODEOWNER bypass. Resolves the contradiction where `trust-dial-gate.yml`
  evaluated Dependabot PRs that the tier rule could never let merge.
- `docs/branch-governance.md`: document that dev-sync PRs (`main -> dev`) must be
  merged with a merge commit (`gh pr merge --merge`), never squash/rebase, so
  `dev` stays a true descendant of `main` under the `non_fast_forward` ruleset.

### Fixed

- `.gitignore`: ignore hook-generated OPA scan artifacts (`opa-input.json`,
  `opa-eval.stdout`, `opa-eval.stderr`, `verdict.json`) so blast-radius /
  conformance hook byproducts no longer leak into the untracked working set.

## [3.1.0] - 2026-06-09

### Added

- `scripts/bootstrap_test.sh` — a regression test that bootstraps every artifact
  type and asserts a clean leftover-token scan, `opa check`/`opa test`, and a
  passing conformance self-check.
- Golden-repo gates carried into every bootstrapped repo via `template/_files/`:
  an `agentic-gates` job in `.github/workflows/conformance.yml`,
  `scripts/preflight.sh`, `docs/adr/ADR-000-template.md`,
  `docs/claude-settings.template.json`, and a "Capability Roster" section in
  `AGENTS.md`. All are TIER-2/TIER-3 — no new conformance-required file is added.

### Changed

- `scripts/publish.sh` — add a `gh` preflight (binary presence + auth status)
  that runs in both dry-run and `--confirm` paths so missing tooling surfaces
  before any gate has passed; pass `--accept-visibility-change-consequences`
  on the public-visibility flip so the script no longer requires interactive
  confirmation.
- `.github/workflows/commitlint.yml`: skip commit-message validation on dev-sync PRs (where
  `github.event.pull_request.head.ref == 'main'`). These PRs propagate commits that already
  passed validation when they landed on main via the standard PR flow; re-validating them would
  block dev-sync on historical grandfathered commits (e.g. `2f6312b` `bd:` typo before the
  type-enum was enforced).
- `lefthook.yml`: new `pre-push` `block-beads-paths` command rejects any push touching
  `.beads/`, `.dolt/`, or `.beads-credential-key`. Defense-in-depth — `.gitignore` already
  covers these, but a force-add or a `.gitignore` drift could let them slip into a commit.

### Security

- Pin third-party GitHub Actions to immutable commit SHAs across
  `.github/workflows/ci.yml` (4× `actions/checkout`, 1× `open-policy-agent/setup-opa`)
  and `.github/workflows/commitlint.yml` (1× `actions/checkout`). Resolved:
  `actions/checkout` v4.2.2 → `11bd71901bbe5b1630ceea73d27597364c9af683`;
  `open-policy-agent/setup-opa` v2.4.0 → `b2b258e089860efaadaaf71bf6e3aecb4a3eeff1`.
  Closes the upstream-tag-overwrite vector for CI.

## [3.0.0] - 2026-05-22

### Added (BREAKING — new required files and a new error-severity deny family)

- `conformance/blast_radius.rego` — blast-radius pulse verdict policy.
  Pure deterministic Rego function under package `kellerai.oss.blast_radius`;
  consumes a change set + the affects manifest as `input` and `data`; emits
  exactly one verdict (`clear` | `owed` | `blocked`).
- `conformance/affects.json` — declarative affects manifest. Thirteen seed
  entries (BR-001..BR-013) cover the cross-file pairs named in the
  cross-discipline panel, plus catch-all entries that satisfy the new
  `affects_manifest_complete` deny family for every tracked file under
  `conformance/`, `template/`, `scripts/`, and `docs/agents/`.
- `conformance/blast_radius_test.rego` — `opa test` suite proving determinism
  of the pulse policy across every seed entry plus the empty-diff baseline
  plus the sub-target gate plus the rationale string contract.
- `scripts/pulse.sh` — wrapper around `opa eval data.kellerai.oss.blast_radius.result`.
  Three modes: `live` (reads `git diff --name-only --cached` for lefthook),
  `audit` (reads `git diff --name-only <range>` for the CI gate), `predict`
  (hypothetical change set from positional file globs). Parses
  `Pulse-Action: <id> DONE` footer lines from the pending commit message to
  declare required actions satisfied.
- `.github/workflows/blast-radius-pulse.yml` — PR-triggered gate workflow that
  evaluates the pulse against the PR diff; least-privilege permissions
  (`contents: read`, `pull-requests: write`); posts a sticky PR comment;
  uploads a 90-day trace artifact; fails the job on a `blocked` verdict.
- `.github/workflows/blast-radius-outcome.yml` — post-gate outcome workflow
  keyed on `workflow_run` of the gate; downloads the gate's trace fragment;
  appends one line to `audit/blast-radius.jsonl`; commits the trace back to
  `main` with the `[skip ci]` marker and the three recursion-break guards.
- `audit/blast-radius.jsonl` — committed append-only pulse trace. Bootstrap
  seed line written at v3.0.0; live verdicts appended by the outcome workflow.
- `docs/adr/ADR-002-blast-radius-pulse.md` — the architecture decision record
  for this build.
- `affects_manifest_complete` deny family in `conformance/conformance.rego`
  (error severity) — proves the affects manifest covers every tracked file in
  pulse scope (`conformance/`, `template/`, `scripts/`, `docs/agents/`).
  Mirrors the shape of `trust_dial_wired` (ADR-001).
- Templatized copies of every artifact above under `template/_files/` so every
  bootstrapped repo ships the blast-radius pulse by construction.
- `blast-radius-pulse` command added to `lefthook.yml` pre-commit; the live
  surface rejects commits that owe required actions on any error-severity
  rule. `--commit-msg-file {commit_msg_file}` is passed through so the
  hook can parse `Pulse-Action: <id> DONE` footer lines.

### Changed (BREAKING — manifest tightening)

- `conformance/data.json`: new top-level `blast_radius_manifest` section
  describing the policy, manifest, test suite, trace, gate + outcome workflows,
  and the pulse-scope directory list.
- `conformance/data.json`: `conformance/affects.json`,
  `conformance/blast_radius.rego`, `conformance/blast_radius_test.rego`,
  `audit/blast-radius.jsonl`, and `docs/adr/ADR-002-blast-radius-pulse.md`
  added to `schema.required_files`.
- `conformance/data.json`: `.github/workflows/blast-radius-pulse.yml` and
  `.github/workflows/blast-radius-outcome.yml` added to
  `schema.required_github_files`.
- `conformance/data.json`: `scripts/pulse.sh` added to
  `schema.required_scripts`.
- `conformance/data.json`: `policy_integrity.expected_digest` refrozen from
  `011d17904bc7dd6606d498c497d4b43a99c0556f43c1ddcedf839177249dbcec` to
  `c71bce43c79439e52526ad85ba34aa2238e230ec624d03718098d0416a41a38b`
  (SHA-256 of `conformance/conformance.rego` after the
  `affects_manifest_complete` family was added). The refreeze is itself
  recorded as a new entry in `audit/decision-trace.jsonl` (event
  `policy_integrity_refreeze`) — closing G-11 a second time.
- `conformance/conformance_test.rego`: happy-path fixture extended to list
  the four new required-file paths plus the two new required github-files
  plus `scripts/pulse.sh` so the existing tests still pass against the new
  manifest.
- `lefthook.yml`: `blast-radius-pulse` command added alongside existing
  `opa-check`, `opa-test`, and `sanitization` commands; `parallel: true` is
  preserved.

### Recursion guards (CI write-back loop)

The blast-radius outcome workflow writes `audit/blast-radius.jsonl`. Three
independent guards prevent a feedback loop, identical in shape to ADR-001's:

1. `paths-ignore: ['audit/**']` on `pull_request` in the gate workflow.
2. `[skip ci]` marker on the outcome workflow's write-back commit message.
3. Author-identity guard on the outcome workflow — exits early if the
   triggering workflow run was authored by `github-actions[bot]`.

### Migration

- Already-bootstrapped repos must add the five new required files
  (`conformance/affects.json`, `conformance/blast_radius.rego`,
  `conformance/blast_radius_test.rego`, `audit/blast-radius.jsonl`,
  `docs/adr/ADR-002-blast-radius-pulse.md`) plus the two new workflows plus
  `scripts/pulse.sh`, or fail the `required_file` / `required_github_file` /
  `required_script` conformance checks. See `docs/adoption-guide.md` (the
  migration entry for v3.0.0 is a follow-up doc PR).

### Routed open questions

- The `conformance/affects.json` manifest required four extra catch-all
  entries (BR-010 scripts/**, BR-011 affects.json, BR-012 docs/agents/**,
  BR-013 template/**) beyond the nine in the spec's seed in order to satisfy
  the `affects_manifest_complete` deny family. Whether to fold these into the
  spec's seed or treat them as repo-specific is OQ-6.
- The gate workflow uses `gh pr comment` rather than
  `marocchino/sticky-pull-request-comment` because no verified SHA pin for
  that action exists in the existing workflow set; sticky-comment behaviour
  is therefore not yet enforced (every gate run posts a new comment). Tracked
  as OQ-7 for a follow-up PR.
- The outcome workflow's recursion-guard step is conservative — it exits
  early on any `github-actions[bot]` actor rather than checking the touched
  path set. This is the safe default; a tighter check requires the workflow
  to fetch the commit's file list (OQ-8).
- OQ-1..OQ-5 in `blast-radius-pulse-spec.md` §9 remain open.

## [2.0.0] - 2026-05-22

### Added (BREAKING — new required files and a new error-severity deny family)

- `conformance/trust_dial.rego` — trust-dial Dependabot auto-merge verdict
  policy. Pure deterministic Rego function under package
  `kellerai.oss.trust_dial`; no I/O, no time-dependent inputs.
- `conformance/trust_dial_data.json` — tier × ecosystem × update-type verdict
  matrix, promotion thresholds, weekly budget cap, circuit-breaker thresholds,
  and BakeTracker cycle requirement.
- `conformance/trust_dial_test.rego` — `opa test` suite proving determinism of
  the verdict policy across the full matrix plus fail-safe cases.
- `.github/workflows/trust-dial-gate.yml` — gate workflow that evaluates the
  verdict policy on every Dependabot PR; least-privilege permissions
  (`contents: read`, `pull-requests: write`); uploads a 90-day trace artifact.
- `.github/workflows/trust-dial-outcome.yml` — post-merge outcome workflow
  keyed on `workflow_run` of CI; drives the streak / promotion / demotion
  ladder; commits state and trace updates back to the repo with the
  recursion-break guards in place.
- `audit/` directory: `audit/trust-dial-state.json` (single-writer state file,
  initialized to tier `Observed` per whitepaper §11) and
  `audit/decision-trace.jsonl` (append-only committed decision trace).
- `docs/adr/ADR-001-trust-dial-dependabot.md` — the architecture decision
  record for this build.
- `trust_dial_wired` deny family in `conformance/conformance.rego` (error
  severity) — proves the gate workflow is wired into CI, not merely present.
- Templatized copies of every artifact above under `template/_files/` so every
  bootstrapped repo ships a wired trust-dial gate by construction.

### Changed (BREAKING — manifest tightening)

- `conformance/data.json`: new `trust_dial` section describing the verdict
  policy, data, state file, decision trace, and the two workflows.
- `conformance/data.json`: `audit` added to `schema.required_dirs`.
- `conformance/data.json`: `.github/workflows/trust-dial-gate.yml` and
  `.github/workflows/trust-dial-outcome.yml` added to
  `schema.required_github_files`.
- `conformance/data.json`: `policy_integrity.expected_digest` refrozen from
  `c781ea87fa61173f2cf1651d29c5246f111f54044bff30495cd5e34c52bf3c61` to
  `011d17904bc7dd6606d498c497d4b43a99c0556f43c1ddcedf839177249dbcec`
  (SHA-256 of `conformance/conformance.rego` after the `trust_dial_wired`
  family was added). The refreeze is itself recorded as an entry in
  `audit/decision-trace.jsonl` (event: `policy_integrity_refreeze`) —
  closing G-11.
- `.github/workflows/ci.yml`, `.github/workflows/pages.yml`, and the templated
  copies under `template/_files/`: `paths-ignore: ['audit/**']` added to every
  `push:` and `pull_request:` trigger so trust-dial state write-back commits
  do not re-trigger sibling CI (recursion guard 1 of 3).

### Migration

- Already-bootstrapped repos must add the `audit/` directory (with the two
  seed files) and the two trust-dial workflows, or fail the `required_dir` and
  `required_github_file` conformance checks. See `docs/adoption-guide.md`.
- A freshly bootstrapped repo starts at tier `Observed` per whitepaper §11.

### Routed open questions

- The spec's `{{ISO_DATE}}` bootstrap token was NOT added — user-stated
  invariants restrict the token vocabulary to the existing set. The template
  ships `audit/trust-dial-state.json` with a fixed sentinel `init.ts` of
  `2026-05-22T00:00:00Z`; per-repo timestamping deferred (see OQ-7).
- OQ-1..OQ-6 in `trust-dial-dependabot-spec.md` §9 remain open.

### Changed

- `scripts/bootstrap.sh` is hardened against incident classes IC-1..IC-7: a
  dependency preflight, fail-fast validation of every flag, atomic generation in
  a temp staging tree (a failure never leaves a partial tree at `--out`), a
  `--force` no-clobber guard, a leftover-token scan, and a post-generation OPA
  conformance self-check. Generated repos are now golden-conformant by
  construction.

### Fixed

- `scripts/bootstrap.sh`: skip non-text files (e.g. `.DS_Store`) during token
  substitution. The sed loop previously errored with `RE error: illegal byte
  sequence` if the template tree picked up local macOS Finder cruft; CI is
  unaffected (fresh checkout has no cruft), but local runs of
  `bootstrap_test.sh` could fail. The loop now uses `grep -Iq .` to skip
  binary or empty files before invoking sed.

## [0.1.0] - 2026-05-21

### Added

- Initial conformance suite (`12fcfc7`): `conformance/conformance.rego`
  (OPA policy implementing the OSS publication rules), `conformance/conformance_test.rego`
  (22 tests covering every deny rule), and `conformance/data.json`
  (data-driven manifest of required files, directories, artifact types,
  thresholds, and policy-integrity digest).
- `scripts/scan-repo-structure.sh` — emits the JSON snapshot consumed by
  the conformance policy at evaluation time.
- `scripts/bootstrap.sh` — stamps a new conformant repository from the
  `template/_files/` scaffold via token substitution; supports four
  artifact types (`json-schema`, `markdown-spec`, `rego-policy`,
  `rag-config`) and three SPDX licenses (`Apache-2.0`, `CC-BY-4.0`, `MIT`).
- `scripts/check-sanitization.sh` — sanitization regression gate that
  scans every tracked file against a base64-encoded denylist of internal
  terms (placeholder stub at this release; adopters supply their own
  denylist).
- `standard/OSS-PUBLICATION-STANDARD.md` — the normative OSS publication
  standard that the conformance policy encodes.
- `template/_files/` — the full tokenized golden-repo scaffold: `README.md`,
  `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `SECURITY.md`, `CITATION.cff`,
  `NOTICE`, `CHANGELOG.md`, `LICENSE` (per-license bodies in `template/licenses/`),
  `docs/agents/` (conventions, citation, glossary, enforcement),
  `.github/` (CODEOWNERS, dependabot, PR + issue templates), and the
  CI workflow scaffolding (`ci.yml`, `commitlint.yml`, `pages.yml`).
- `.github/workflows/conformance.yml` — reusable workflow consumed by
  bootstrapped repos via `uses: jonathan-kellerai/kellerai-oss-template/.github/workflows/conformance.yml@<sha>`.
- `commitlint.config.js`, `lefthook.yml`, `.markdownlint-cli2.yaml`,
  `.gitignore` — required tooling configuration baselines.

## [0.2.0] - 2026-05-22

### Added

- Four-tier branch governance model (external → dev → qa → main) with three gate workflows:
  `validate-branch-name`, `validate-branch-tier`, and `validate-linked-issue` under
  `.github/workflows/`; templated copies under `template/_files/.github/workflows/` for
  bootstrapped repos; and `docs/branch-governance.md` documenting the model.

### Changed

- **BREAKING:** the three branch-governance workflows are now listed in `required_github_files`
  in `conformance/data.json` — every conformant kellerai repo must provide them. Consumers pin
  a SHA, so this takes effect on each consumer's next pin bump.

### Fixed

- CI: pinned `markdownlint-cli2` to an exact version in `.github/workflows/ci.yml` (was floating
  `npx --yes`, which silently broke when a new markdownlint release added rule MD060).
- CI: disabled MD060 (cosmetic table-column-style) and MD041 (conflicts with the mandated
  `@AGENTS.md` first line of `CLAUDE.md`) in `.markdownlint-cli2.yaml`; fixed 15 genuine
  markdown errors (missing code-fence languages, bare URLs, list spacing) across `docs/` and
  `README.md`.
- CI: fixed a silent-failure in the reusable conformance workflow
  (`.github/workflows/conformance.yml`) — the policy-evaluation step discarded `opa eval`
  stderr and ignored its exit code, so a failed evaluation reported only
  `(no output from opa eval)`. It now captures stderr, checks the exit code, surfaces the real
  error, and uses `--format json`.
