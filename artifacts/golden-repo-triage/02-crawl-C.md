---
status: complete
run_id: golden-repo-triage-2026-05-22
phase: Phase 2 — Marketplace crawl (Agent C)
completed_at: 2026-05-22T08:10:00Z
---

# Phase 2 — Crawl Agent C: scaffolding / docs / template / CI

Authored by orchestrator `GoldenHarbor` from Crawl Agent C's returned report (Explore agents have no Write tool — see WARNING in `02-scored-agents.md`).
Slice: repo scaffolding, repo generation, documentation, template, CI-authoring plugins. 11 plugins crawled.

## D3 — repo-architecture / scaffolding

| Plugin | Tier | C1 | C2 | C3 | C4 | C5 | Raw/50 | Norm% | Rationale + citation |
|--------|------|----|----|----|----|----|--------|-------|----------------------|
| kellerai-repo-audit | ACTIVE | 5 | 5 | 5 | 5 | 5 | 50 | 100% | 6-wave architecture audit + roadmap scaffolding; OPA-enforced validation; per-wave artifacts + PDF; cmux + SQLite telemetry. `cache/kellerai-dev-marketplace/kellerai-repo-audit/1.4.0/.claude-plugin/plugin.json:description` |
| kellerai-skill-creator | ACTIVE | 5 | 5 | 5 | 5 | 5 | 50 | 100% | Scaffolds skills as repo components; OPA conformance enforcement; emits transcript + metrics + grading.json; eval/improve agents. `cache/.../kellerai-skill-creator/2.1.1/.claude-plugin/plugin.json:description` |
| plugin-dev | ACTIVE | 5 | 3 | 4 | 5 | 4 | 41 | 82% | Scaffolds plugins, skills, commands, agents; guidance-focused, low enforceability. `cache/claude-plugins-official/plugin-dev/.claude-plugin/plugin.json:description` |
| frontend-mobile | ACTIVE | 5 | 3 | 4 | 5 | 3 | 40 | 80% | Component/UI/design-system scaffolding; tangential to repo-architecture. `cache/.../frontend-mobile/2.7.1/.claude-plugin/plugin.json:description` |

## D5 — CI/CD authoring

| Plugin | Tier | C1 | C2 | C3 | C4 | C5 | Raw/50 | Norm% | Rationale + citation |
|--------|------|----|----|----|----|----|--------|-------|----------------------|
| kellerai-repo-audit | ACTIVE | 5 | 5 | 5 | 5 | 5 | 50 | 100% | Detects CI/CD gaps (Wave 1), golden-pattern verification (Wave 2), roadmap seeding; OPA-enforced. (see D3 entry) |
| git-workflow-tools | ACTIVE | 4 | 5 | 5 | 4 | 4 | 45 | 90% | Audited git workflow; commitlint + ubs + version checks via PreToolUse guard. `cache/.../git-workflow-tools/0.16.5/.claude-plugin/plugin.json:description` |

Note: Agent A (orchestration/git slice) scored `git-workflow-tools` for D5 at 98%; this slice scored it 90%. The master deliverable uses Agent A's 98% as primary (git-workflow-tools is in Agent A's slice).

## D7 — documentation

| Plugin | Tier | C1 | C2 | C3 | C4 | C5 | Raw/50 | Norm% | Rationale + citation |
|--------|------|----|----|----|----|----|--------|-------|----------------------|
| documentation-audit | DISABLED | 5 | 5 | 5 | 1.5 | 2 | 43.5 | 87% | 6-agent doc audit; P0-P3 severity + JSON findings + ready-to-apply diffs; Beads integration. `cache/.../documentation-audit/0.13.1/.claude-plugin/plugin.json:description` |
| claude-md-management | ACTIVE | 5 | 4 | 4 | 4 | 3 | 42 | 84% | Scaffolds/audits CLAUDE.md; quality-score rubric; targeted diffs. `cache/claude-plugins-official/claude-md-management/1.0.0/.claude-plugin/plugin.json:description` |
| human-writing | ACTIVE | 4 | 4 | 3 | 4 | 2 | 36 | 72% | Removes AI-writing patterns; pattern-detection rules; minimal artifact trail. `cache/.../human-writing/2.4.1/.claude-plugin/plugin.json:description` |
| keller-render | ACTIVE | 3 | 4 | 3 | 4 | 3 | 34 | 68% | Design-system palette + WeasyPrint PDF/HTML rendering; support role. `cache/.../keller-render/1.1.0/.claude-plugin/plugin.json:description` |
| cli-skills | DISABLED | 2 | 2 | 2 | 1 | 1 | 18 | 36% | CLI routing/reference; low scaffolding/doc fit. `cache/.../cli-skills/1.8.1/.claude-plugin/plugin.json:description` |

## #1 picks (Agent C)

- D3: **kellerai-repo-audit** (100%, tie with kellerai-skill-creator).
- D5: **kellerai-repo-audit** (100%); secondary git-workflow-tools.
- D7: **documentation-audit** (87%, DISABLED); top ACTIVE = claude-md-management (84%).

## Multi-domain plugins flagged

- `kellerai-repo-audit` → D3 + D5 (+ D2 per Agent B). Conflict resolved in master deliverable.
- `frontend-mobile` → D3 + D7 (design docs / style guides).
- `keller-render` → D7 + D5 (PDF/HTML CI artifacts).
