---
status: complete
run_id: golden-repo-triage-2026-05-22
phase: Phase 2 — Marketplace crawl (Agent B)
completed_at: 2026-05-22T08:10:00Z
---

# Phase 2 — Crawl Agent B: code-analysis / review / conformance / policy

Authored by orchestrator `GoldenHarbor` from Crawl Agent B's returned report (Explore agents have no Write tool — see WARNING in `02-scored-agents.md`).
Slice: static analysis, code review, conformance, policy plugins. 9 plugins crawled.

## D2 — plugin-&-capability-analysis

| Plugin | Tier | C1 | C2 | C3 | C4 | C5 | Raw/50 | Norm% | Rationale + citation |
|--------|------|----|----|----|----|----|--------|-------|----------------------|
| keller-pr-review | ACTIVE | 5 | 5 | 5 | 5 | 5 | 50 | 100% | ThoughtBox pre-analysis + 4 parallel specialist agents; diff-validated findings; HTML report + batched inline comments + GitHub issues. `cache/kellerai-dev-marketplace/keller-pr-review/0.57.0/plugin.json` |
| kellerai-repo-audit | ACTIVE | 5 | 4 | 5 | 5 | 5 | 47 | 94% | Multi-wave audit (security, drift, duplication, compliance); OPA gates; SQLite telemetry. `cache/kellerai-dev-marketplace/kellerai-repo-audit/1.3.0/plugin.json` |

## D4 — conformance-&-policy (OPA/Rego)

| Plugin | Tier | C1 | C2 | C3 | C4 | C5 | Raw/50 | Norm% | Rationale + citation |
|--------|------|----|----|----|----|----|--------|-------|----------------------|
| kellerai-grc | DISABLED | 5 | 5 | 5 | 2.5 | 2.5 | 35 | 70% | Graduated GRC enforcement (3 tiers incl. `/grc` blocking gate); Z3 formal verification; Rego/OPA validation; SOC2/HIPAA/GDPR packs. `cache/.../kellerai-grc/0.8.1/agents/grc-pack-validator-agent.md` |
| opa-rego | DISABLED | 5 | 4 | 5 | 2.5 | 2.5 | 34 | 68% | OPA/Rego authoring, testing, linting; SARIF 2.1.0 reporter for GitHub Advanced Security; data-driven validation. `cache/.../opa-rego/0.3.1/agents/rego-sarif-reporter-agent.md` |
| kellerai-tdd | DISABLED | 4 | 4 | 4 | 2.5 | 2.5 | 31 | 62% | Graduated TDD coaching with `/tdd` blocking gates; enforcement-gap detection. `cache/.../kellerai-tdd/0.15.1/plugin.json` |

## Other candidates (cross-domain / general)

| Plugin | Tier | C1 | C2 | C3 | C4 | C5 | Raw/50 | Norm% | Rationale + citation |
|--------|------|----|----|----|----|----|--------|-------|----------------------|
| pr-review-toolkit | ACTIVE | 5 | 4 | 4 | 5 | 4 | 46 | 92% | PR review agents (comments, tests, error handling, type design); advisory, no machine gate. `cache/claude-plugins-official/pr-review-toolkit/plugin.json` |
| kellerai-ubs | ACTIVE | 4 | 5 | 3 | 5 | 4 | 44 | 88% | Ultimate Bug Scanner; real-time static analysis, 1000+ patterns, 8 languages; advisory. `cache/kellerai-hooks/kellerai-ubs/1.0.0/skills/ubs-scan/SKILL.md` |
| keller-branch-audit | BENCHED | 5 | 4 | 5 | 0 | 0 | 27 | 54% | 3-level agent hierarchy; severity-gated P0-P4 findings. Not installed. `cache/.../keller-branch-audit/0.15.1/plugin.json` |
| documentation-audit | BENCHED | 4 | 3 | 4 | 0 | 0 | 19 | 38% | 6-agent doc audit pipeline. Not installed. `cache/.../documentation-audit/0.13.1/plugin.json` |

## #1 picks (Agent B)

- D2: **keller-pr-review** (100%).
- D4: **kellerai-grc** (70%, DISABLED).

## Multi-domain plugins flagged

- `kellerai-repo-audit` → D2 + D4 (OPA validation + architecture/security analysis).
- `keller-pr-review` → D2 + D3 (code review with architecture implications).
- `kellerai-grc` → D4 + D6 (policy enforcement + compliance decision records).
