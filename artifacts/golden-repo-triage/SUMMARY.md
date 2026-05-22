---
run_date: 2026-05-22
run_id: golden-repo-triage-2026-05-22
agent_skill_index_digest: c33d65dad1a46397160eb64abe6c04d8a2def4a61b62699b6a42a0dd52008fba
domains_covered:
  - name: D1 session-mining/log-analysis
    gate_count: 1
    served: true
  - name: D2 plugin-&-capability-analysis
    gate_count: 2
    served: true
  - name: D3 repo-architecture/scaffolding
    gate_count: 1
    served: true
  - name: D4 conformance-&-policy
    gate_count: 2
    served: true
  - name: D5 CI/CD authoring
    gate_count: 2
    served: true
  - name: D6 governance-&-decision-traceability
    gate_count: 1
    served: true
  - name: D7 documentation
    gate_count: 2
    served: true
phases_completed:
  - phase: "Phase 0"
    status: complete
  - phase: "Phase 1"
    status: complete
  - phase: "Phase 2"
    status: complete
  - phase: "Phase 3"
    status: complete
top5_changes:
  - id: ADR-001
    title: Adopt thoughtbox as the D1 session-mining capability
    incident_ref: "01-incident-ledger.md:35"
    score_ref: "02-scored-agents.md:46"
  - id: ADR-003
    title: Adopt kellerai-repo-audit for D3 repo-architecture/scaffolding
    incident_ref: "01-incident-ledger.md:33"
    score_ref: "02-scored-agents.md:66"
  - id: ADR-004
    title: Adopt opa-rego as D4 conformance-&-policy primary
    incident_ref: "01-incident-ledger.md:39"
    score_ref: "02-scored-agents.md:77"
  - id: ADR-005
    title: Adopt git-workflow-tools as the D5 CI/CD capability
    incident_ref: "01-incident-ledger.md:38"
    score_ref: "02-scored-agents.md:86"
  - id: ADR-006
    title: Adopt kellerai-feature-spec for D6 governance-&-decision-traceability
    incident_ref: "01-incident-ledger.md:34"
    score_ref: "02-scored-agents.md:96"
---

# Golden-Repo Design — Summary

This is a derived subset of the authoritative design document `03-golden-repo-design.md`.
Every claim here also appears there.

## Recommended design (for human readers)

The golden repo is **`kellerai-oss-template` itself, extended** — not a new repository. It keeps its
identity as the OPA/Rego conformance authority and bootstrap scaffold (artifact type `rego-policy`)
and adds one documented, machine-enforced answer per triage domain.

The design is governed by a **three-tier enforcement model** so comprehensiveness does not break the
repo's minimalism: TIER-1 is the existing conformance-required file set (no additions); TIER-2 is CI
behavioral gates added as steps inside the already-required `conformance.yml` workflow; TIER-3 is
named conventions in `AGENTS.md`. The result adds **zero new conformance-required files and triggers
zero major semver bumps** — every `[NEW]` component is optional or CI-only.

Each of the 7 mined incident classes (IC-1..IC-7) maps to a gate, and each of the 7 domains has at
least one machine-checked gate. The two DISABLED-tier picks (`opa-rego` for D4, `documentation-audit`
for D7) carry an enable recommendation in the migration note, per the user's Phase 0 decision.

The migration note proposes **no change to `conformance/conformance.rego` or `conformance/data.json`**;
the baseline was verified green (`opa check` exit 0; `opa test` 22/22 PASS).

### Top 5 evidence-backed changes

| ADR | Change | Incident | Capability score |
|-----|--------|----------|------------------|
| ADR-001 | Adopt `thoughtbox` for D1 session-mining | IC-3 session-context loss (`01-incident-ledger.md:35`) | thoughtbox 94% (`02-scored-agents.md:46`) |
| ADR-003 | Adopt `kellerai-repo-audit` for D3 scaffolding | IC-1 preflight-dir (`01-incident-ledger.md:33`) | kellerai-repo-audit 100% (`02-scored-agents.md:66`) |
| ADR-004 | Adopt `opa-rego` as D4 conformance primary | IC-7 publication-readiness (`01-incident-ledger.md:39`) | opa-rego 68% (`02-scored-agents.md:77`) |
| ADR-005 | Adopt `git-workflow-tools` for D5 CI/CD | IC-6 dirty-state-commit (`01-incident-ledger.md:38`) | git-workflow-tools 98% (`02-scored-agents.md:86`) |
| ADR-006 | Adopt `kellerai-feature-spec` for D6 governance | IC-2 phase-wiring (`01-incident-ledger.md:34`) | kellerai-feature-spec 100% (`02-scored-agents.md:96`) |

## Scored-agent roster (machine section)

```yaml
canonical_roster:
  D1_session_mining:
    pick: thoughtbox
    tier: ACTIVE
    normalized: 94
    raw_of_50: 47
    runners_up:
      - {plugin: token-triage-analyzer, tier: BENCHED, normalized: 54}
      - {plugin: log-compressor-tools, tier: BENCHED, normalized: 48}
  D2_plugin_capability_analysis:
    pick: kellerai-repo-audit
    tier: ACTIVE
    normalized: 94
    raw_of_50: 47
    note: keller-pr-review scored 100% but is repositioned as the PR-workflow gate (XC-2)
  D3_repo_architecture_scaffolding:
    pick: kellerai-repo-audit
    tier: ACTIVE
    normalized: 100
    raw_of_50: 50
    runners_up:
      - {plugin: kellerai-skill-creator, tier: ACTIVE, normalized: 100}
      - {plugin: plugin-dev, tier: ACTIVE, normalized: 82}
      - {plugin: frontend-mobile, tier: ACTIVE, normalized: 80}
  D4_conformance_policy:
    pick: opa-rego
    tier: DISABLED
    normalized: 68
    raw_of_50: 34
    secondary: {plugin: kellerai-grc, tier: DISABLED, normalized: 70, role: on-demand-audit}
    runners_up:
      - {plugin: kellerai-tdd, tier: DISABLED, normalized: 62}
  D5_cicd_authoring:
    pick: git-workflow-tools
    tier: ACTIVE
    normalized: 98
    raw_of_50: 49
    runners_up:
      - {plugin: beads-workflow, tier: ACTIVE, normalized: 96}
      - {plugin: kellerai-orchestrator, tier: ACTIVE, normalized: 94}
      - {plugin: tdd-workflow, tier: BENCHED, normalized: 54}
  D6_governance_decision_traceability:
    pick: kellerai-feature-spec
    tier: ACTIVE
    normalized: 100
    raw_of_50: 50
    runners_up:
      - {plugin: thoughtbox, tier: ACTIVE, normalized: 96}
      - {plugin: beads-workflow, tier: ACTIVE, normalized: 92}
      - {plugin: git-workflow-tools, tier: ACTIVE, normalized: 82}
      - {plugin: handoff-prompt-author, tier: ACTIVE, normalized: 78}
      - {plugin: kellerai-grc, tier: DISABLED, normalized: 62}
      - {plugin: exec-summary, tier: DISABLED, normalized: 50}
  D7_documentation:
    pick: documentation-audit
    tier: DISABLED
    normalized: 87
    raw_of_50: 43.5
    secondary: {plugin: claude-md-management, tier: ACTIVE, normalized: 86, role: active-tier-companion}
    runners_up:
      - {plugin: human-writing, tier: ACTIVE, normalized: 72}
      - {plugin: keller-render, tier: ACTIVE, normalized: 68}
      - {plugin: cli-skills, tier: DISABLED, normalized: 36}
      - {plugin: remember, tier: BENCHED, normalized: 30}
conflict_resolutions:
  XC-1: opa-rego is D4 primary; kellerai-grc retained on-demand
  XC-2: kellerai-repo-audit is the D2 standard; keller-pr-review repositioned as PR-workflow gate
  XC-3: ship docs/claude-settings.template.json (tracked); adopters copy to .claude/settings.json
  XC-4: three-tier enforcement model — zero new conformance-required files
incident_gate_coverage:
  IC-1_preflight_dir: scripts/preflight.sh step in agentic-gates job
  IC-2_phase_wiring: agentic-gates declared-artifact-path assertion
  IC-3_session_context: claude_md_import deny rule + handoff-file convention
  IC-4_permission_allowlist: docs/claude-settings.template.json + checksum warn-step
  IC-5_retry_policy: bounded-retry CI steps + documented convention
  IC-6_dirty_state_commit: lefthook pre-commit + agentic-gates dirty-tree check
  IC-7_publication_readiness: agentic-gates readiness step + policy_integrity deny rule
verification:
  opa_check: exit 0
  opa_test: 22/22 PASS
  conformance_changes_proposed: 0
  adr_count: 11
  major_choices: 11
  citation_self_check: {tokens: 66, adrs_uncited: 0}
warnings:
  - Phase 2 file reservation skipped — plugin cache is outside the project root; mail tool rejects out-of-project paths; read-only crawl so the advisory lease is moot
  - Crawl artifacts authored by the orchestrator — the Explore agent type has no Write tool; subagents returned reports, main chat wrote 02-crawl-A..E.md and 02-scored-agents.md
  - No monitor tool found — hub heartbeats used for progress observability
```
