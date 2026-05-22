---
status: complete
run_id: golden-repo-triage-2026-05-22
phase: Addendum — From-scratch build-out plan
completed_at: 2026-05-22T08:40:00Z
---

# Golden-Repo Build-Out Plan — From Scratch, Deterministic & Provable

How to construct the golden repo from an empty directory so the result is
**correct** (passes conformance), **repeatable** (same inputs → same tree),
**conformant** (zero error-severity violations), **deterministic** (no
free choices in the procedure), and **provable** (every phase ends with a
command whose exit code is the proof).

This plan operationalizes `03-golden-repo-design.md`. It does not replace it —
`03` is the design; this is the construction procedure.

---

## Determinism principles (why the output is reproducible)

1. **Single source of truth.** `conformance/data.json` enumerates every
   required file, directory, `.github` file, agent doc, script, and artifact
   type. The repo tree is a *function of* `data.json` — not authored freehand.
2. **Tokenized scaffold.** The repo is generated from `template/` with a fixed
   token map (owner, slug, license, year). No file is hand-placed.
3. **Ordered, idempotent phases.** Phases 0→6 run in order; re-running a phase
   yields the same state. No phase depends on a later phase.
4. **Proof after every phase.** Each phase below ends with a `PROOF:` command.
   A phase is complete only when its proof exits 0. No "looks done" — the gate
   decides.
5. **Frozen policy.** `conformance/conformance.rego` is SHA-256-pinned via
   `data.json` `policy_integrity.expected_digest`; the policy cannot drift
   silently across rebuilds.

---

## Phase 0 — Environment lock

**Goal:** pin every tool version so two operators on two machines build byte-identical results.

**Actions:**
- Record exact versions: `opa` (1.14.1), `node` + `npx` (for `ajv`,
  `markdownlint-cli2`, `commitlint`), `lefthook`, `lychee`, `actionlint`,
  `gh`, `git`.
- Commit the version set to `docs/agents/conventions.md` (or a
  `.tool-versions`).

**PROOF:** `opa version` reports `1.14.1`; each other tool reports its pinned
version. Exit 0 on a `scripts/check-versions.sh` that diffs live vs pinned.

---

## Phase 1 — Scaffold from `template/`

**Goal:** materialize the directory skeleton deterministically.

**Actions:**
- `git init` in an empty dir; default branch `main` (standard §0:28 forbids
  `master`).
- Expand `template/` with the fixed token map: owner `jonathan-kellerai`,
  slug = staging dir name, license per repo, year. Use the repo's own
  `scripts/publish.sh` flow — never hand-copy.
- Create the 6 required directories: `.github`, `.github/workflows`,
  `.github/ISSUE_TEMPLATE`, `docs`, `docs/agents`, `scripts`
  (`conformance/data.json` `required_dirs`).

**PROOF:** `bash scripts/scan-repo-structure.sh --artifact-type rego-policy`
emits `repo-structure.json`; every entry in `data.json` `required_dirs` is
present in the snapshot.

---

## Phase 2 — Author the required artifacts

**Goal:** every file in `data.json` exists and passes its type validator.

**Actions (driven by `data.json`, not freehand):**
- 13 root files: `README.md` (humans-only, "For agents" footer),
  `AGENTS.md` (≤150 lines), `CLAUDE.md` (≤80 lines, first content line
  `@AGENTS.md`), `LICENSE`, `NOTICE`, `CHANGELOG.md`, `CITATION.cff`,
  `CONTRIBUTING.md`, `SECURITY.md`, `.gitignore` (must cover `.claude/`,
  `.claude-tmp/`, `.DS_Store`), `.markdownlint-cli2.yaml`,
  `commitlint.config.js`, `lefthook.yml`.
- 10 `.github` files: `CODEOWNERS`, `dependabot.yml`,
  `PULL_REQUEST_TEMPLATE.md`, workflows `ci.yml` / `commitlint.yml` /
  `conformance.yml` / `pages.yml` / `validate-branch-name.yml` /
  `validate-branch-tier.yml` / `validate-linked-issue.yml`,
  `ISSUE_TEMPLATE/config.yml`.
- 4 Tier-2 agent docs: `docs/agents/{conventions,citation,glossary,enforcement}.md`.
- 1 script: `scripts/check-sanitization.sh`.

**PROOF:** each artifact passes its primary validator per
`data.json` `artifact_type_files` (ajv for json-schema, `opa` for
rego-policy, `markdownlint-cli2` for markdown-spec). `git status` clean of
unexpected files.

---

## Phase 3 — Wire and freeze the conformance gate

**Goal:** the policy that proves conformance is itself proven and frozen.

**Actions:**
- Place `conformance/{conformance.rego,conformance_test.rego,data.json,README.md}`.
- Recompute the SHA-256 of `conformance.rego`; write it to
  `data.json` `policy_integrity.expected_digest` (standard §; CLAUDE.md
  "Policy integrity").

**PROOF:** `opa check conformance/` exits 0 **and** `opa test conformance/`
reports `PASS: 22/22`. The `policy_integrity` rule confirms the live digest
equals the manifest digest.

---

## Phase 4 — Apply the golden-repo design additions

**Goal:** add the 5 design components from `03-golden-repo-design.md` §8.
All are Tier-2/Tier-3 — **no `conformance/` change**, so the frozen digest
stays valid and Phase 3's proof is not invalidated.

**Actions (per `03` migration note M1–M8):**
- `agentic-gates` job in `.github/workflows/conformance.yml` — gates IC-1…IC-7.
- `docs/adr/` with `ADR-000-template.md` + seed ADRs 001–011.
- `docs/claude-settings.template.json` — permission allowlist template.
- `scripts/preflight.sh` — artifact-dir + clean-tree preflight.
- `AGENTS.md` "Capability Roster" section — the 7 canonical agents.

**PROOF:** `actionlint .github/workflows/*.yml` exits 0; the `agentic-gates`
job passes on a dry run; ADR-lint confirms each `docs/adr/*.md` has valid
front-matter.

---

## Phase 5 — Full conformance proof

**Goal:** prove the whole repo conformant in one command.

**Actions:**
- Regenerate the snapshot:
  `bash scripts/scan-repo-structure.sh --artifact-type rego-policy`.
- Evaluate the summary rule.

**PROOF (master gate):**
```
opa eval -d conformance/ -i repo-structure.json \
  'data.kellerai.oss.conformance.summary'
```
must return `allow: true`, `errors: 0`. Conformant ≡ zero error-severity
violations (`conformance.rego` `allow := count(errors) == 0`).
Run `scripts/check-sanitization.sh` — exit 0 (no leaked secrets/denylist hits).

---

## Phase 6 — Publication

**Goal:** publish exactly as the standard prescribes — one clean history.

**Actions (standard §17, single-commit procedure):**
- Verify `.gitignore`; ensure working tree is intentional.
- One initial commit (Conventional Commits); `gh repo create` (public,
  owner `jonathan-kellerai`); push once — no force-push, no rebase.
- Optional CHANGELOG follow-up commit; tag `v0.1.0`.

**PROOF:** `gh run list` shows the `conformance.yml`, `ci.yml`,
`commitlint.yml`, `pages.yml` workflows green on the published commit.
CI green on a fresh clone = the build is reproducible off this machine.

---

## The proof chain — what "provable" means here

| Property | Proven by |
|----------|-----------|
| Correct | Phase 5 master gate: `opa eval … summary` → `allow: true` |
| Conformant | `count(errors) == 0` over all 17 `conformance.rego` deny rules |
| Repeatable | Tree is a function of `template/` + `data.json`; re-running Phases 0–5 reproduces it |
| Deterministic | Phase 0 version lock + tokenized scaffold — no free choices in the procedure |
| Policy not drifted | `policy_integrity` rule: live `conformance.rego` digest == `data.json` digest |
| Reproducible off-machine | Phase 6: CI green on a fresh clone |

**Re-build from scratch = re-run Phases 0→6 in order.** Every phase gate must
exit 0 before the next begins; the run is complete only when the Phase 5
master gate returns `allow: true` and Phase 6 CI is green.

---

## Where this plan plugs into the spec→beads pipeline

The spec→beads handoff prompt (provided separately) turns
`03-golden-repo-design.md` into a feature spec and a beads issue graph.
This build-out plan is the **execution order** for those issues: beads
dependency edges should mirror Phases 0→6 here — Phase N issues block
Phase N+1 issues, and the Phase 5 master-gate issue blocks the Phase 6
publication issue.
