---
status: complete
run_id: golden-repo-triage-2026-05-22
phase: Phase 0 — Capability inventory
completed_at: 2026-05-22T07:57:00Z
---

# Phase 0 — Capability Inventory & Domain Definition

Triple-write status: artifact OK | hub post OK (message `6eed1bdd-58b6-443e-a2f1-d83738260db8`) | mail OK.

## WARNING — no monitor tool found

`gateway_tool_search("monitor heartbeat progress observability")` returned no monitoring or heartbeat tool.
The only match was `hydra_drain_status` (score 2), which is unrelated.
Per SETUP Step 4, progress observability for this run uses ThoughtBox hub heartbeats.
Heartbeats post to workspace `515aadaa-8787-4253-9fdd-2ad1d35444aa`, problem channel `f509fdc1-43e5-4cbf-90dd-9a5ec521657b`, at the start and end of every phase.

## AGENT-SKILL-INDEX snapshot (frozen)

- **File:** `~/.claude/configs/agent-catalog/AGENT-SKILL-INDEX.md`
- **SHA-256 digest:** `c33d65dad1a46397160eb64abe6c04d8a2def4a61b62699b6a42a0dd52008fba`
- **Lines:** 1597
- **Date frozen:** 2026-05-22

ThoughtBox reported 0 prior sessions for this project and no pre-existing `00-domains.md`.
No prior-run digest exists to diff against, so the Phase 0 step-2 re-score question does not apply.
All Phase 2 scoring references this frozen snapshot.

## Domains covered

The user confirmed all 7 default domains as-is via `AskUserQuestion` on 2026-05-22.
No domain was added, removed, merged, or renamed.

| ID | Domain | Phase 0 capability finding |
|----|--------|----------------------------|
| D1 | session-mining / log-analysis | UNDER-SERVED risk — no dedicated tooling in the index; `thoughtbox` (enabled) provides session recording but not mining/analysis. |
| D2 | plugin-&-capability-analysis | Served — `plugin-dev` (enabled), `codebase-cartographer` (disabled), `plugin-recommender` (disabled). |
| D3 | repo-architecture / scaffolding | Served — `compound-engineering` architecture agents, `repo-research-analyst`, `kellerai-repo-audit` (enabled). |
| D4 | conformance-&-policy (OPA/Rego) | Served — `opa-rego` (disabled), `kellerai-grc` (disabled); this repo's own `conformance/` policy is the baseline. |
| D5 | CI/CD authoring | Served — `cli-skills` (disabled), `compound-engineering` deployment-verification agents. |
| D6 | governance-&-decision-traceability (ADR/spec) | Served — `kellerai-feature-spec` (enabled), `exec-summary` (disabled), `thoughtbox` (enabled). |
| D7 | documentation | Served — `claude-md-management` (enabled), `human-writing` (enabled), `documentation-audit` (disabled). |

Every domain except D1 has at least one indexed capability.
D1's UNDER-SERVED risk is an accepted, expected outcome — it becomes a Phase 3 action item, not a run failure.

## User decision — disabled domain-critical plugins (Phase 0 step 4)

Question posed: four domain-critical plugins (`opa-rego`, `codebase-cartographer`, `kellerai-tdd`, `kellerai-grc`) are disabled.
Score them from manifest only, or recommend enabling them in the Phase 3 migration note?

**User answer (2026-05-22): score from manifest AND recommend enabling them as part of the Phase 3 migration note.**

Phase 2 scores all four at the DISABLED availability tier (criteria 1–3 scored from manifest; criteria 4–5 tagged `(manifest-only)` at 50% weight).
Phase 3 adds a migration action item recommending each be enabled before the golden repo standardizes on it.

## Plugin status table

Source (full `claude plugin list` output, ground truth): `~/.claude/projects/-Users-jonathans-macbook-oss-staging-kellerai-oss-template/de7bfa26-2725-49a4-8341-eb17200ba1fa/tool-results/b9tu7b628.txt`.

- **Unique plugins:** 112
- **Enabled (ACTIVE tier):** 21
- **Disabled (DISABLED tier):** 91
- **Index totals:** 136 benched agents + 1 active agent; 854 skill records; 1 active skill set.

### ACTIVE tier — 21 enabled plugins

| Plugin | Scope |
|--------|-------|
| `beads-workflow` | user |
| `claude-md-management` | local / project |
| `frontend-mobile` | local |
| `git-workflow-tools` | user |
| `handoff-prompt-author` | user |
| `human-writing` | user / project |
| `kellerai-feature-spec` | user / local |
| `kellerai-intent-router` | user |
| `kellerai-orchestrator` | user |
| `kellerai-repo-audit` | user |
| `kellerai-rtk-rewrite` | user |
| `kellerai-skill-creator` | user |
| `kellerai-ubs` | user |
| `keller-pr-review` | user / local |
| `keller-render` | user |
| `linear` | user / local |
| `morphllm-sdk` | user |
| `plugin-dev` | local |
| `pr-review-toolkit` | user |
| `slack` | user / local |
| `thoughtbox` | user |

### DISABLED tier — domain-critical plugins confirmed disabled

| Plugin | Status | Scope(s) | Version(s) |
|--------|--------|----------|------------|
| `opa-rego` | disabled | local | 0.3.1 |
| `codebase-cartographer` | disabled | local / project | 0.48.1, 0.49.0 |
| `kellerai-tdd` | disabled | local / project | 0.15.1 |
| `kellerai-grc` | disabled | local / project | 0.8.1, 0.7.0 |

The remaining 87 disabled plugins are enumerated in the ground-truth source file above and crawled per-plugin in Phase 2.

## Conformance baseline (anchor for the golden-repo design)

`kellerai-oss-template` already enforces conformance via the OPA/Rego policy `kellerai.oss.conformance`.

- **Required files (13):** `conformance/data.json:4-18`.
- **Required directories (6):** `conformance/data.json:19-26`.
- **Required `.github/` files (10):** `conformance/data.json:27-37`.
- **Required agent docs (4):** `conformance/data.json:39-43`.
- **Artifact types (4):** `json-schema`, `markdown-spec`, `rego-policy`, `rag-config` — `conformance/data.json:48-70`.
- **Deny rule families (17):** `data_sentinel`, `required_file`, `required_dir`, `required_github_file`, `required_agent_doc`, `required_script`, `artifact_type_known`, `artifact_dir`, `agents_md_length`, `claude_md_length`, `claude_md_import`, `readme_agent_footer`, `gitignore_coverage`, `forbidden_branch`, `primary_validator_wired`, `policy_integrity`, `policy_integrity_manifest` — `conformance/conformance.rego:48-264`.

The golden-repo design extends this baseline; it does not replace it.

## Phase 0 exit state

- Domain list: confirmed (7 domains).
- Disabled-plugin handling: decided (score + recommend enabling).
- AGENT-SKILL-INDEX digest: frozen.
- Phase 1 (session mining): dispatched concurrently, running in background.
- Phase 2 gate: domain confirmation satisfied — Phase 2 may dispatch once Phase 1 completes or concurrently per the prompt.
