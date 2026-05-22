---
status: complete
run_id: golden-repo-triage-2026-05-22
phase: Phase 2 — Marketplace crawl (Agent A)
completed_at: 2026-05-22T08:10:00Z
---

# Phase 2 — Crawl Agent A: orchestration / workflow / git

Authored by orchestrator `GoldenHarbor` from Crawl Agent A's returned report (Explore agents have no Write tool — see WARNING in `02-scored-agents.md`).
Slice: orchestration, workflow, task/issue-tracking, git plugins. 5 plugins crawled.

## D5 — CI/CD authoring & enforcement

| Plugin | Tier | C1 | C2 | C3 | C4 | C5 | Raw/50 | Norm% | Rationale + citation |
|--------|------|----|----|----|----|----|--------|-------|----------------------|
| git-workflow-tools | ACTIVE | 5 | 5 | 5 | 5 | 4 | 49 | 98% | 5 commands gate every commit/push via `git_commit_guard.py` PreToolUse hook; `/gm-full` enforces conventional-commit + commitlint + ubs + version-artifact checks. `cache/kellerai-dev-marketplace/git-workflow-tools/0.16.5/README.md:safety-model` |
| beads-workflow | ACTIVE | 5 | 4 | 5 | 5 | 5 | 48 | 96% | Converts plans/specs/alerts into beads epics with DAG dependencies; bridge-orchestrator dedups and sequences. `cache/.../beads-workflow/1.14.0/agents/bridge-orchestrator-agent.md` |
| kellerai-orchestrator | ACTIVE | 5 | 5 | 4 | 5 | 5 | 47 | 94% | Single dispatcher over 13 hook events; capabilities return `Result(decision: block/allow/warn)`. `cache/kellerai-hooks/kellerai-orchestrator/1.7.2/CLAUDE.md:capability-interface` |
| git-workflow-tools (`gm-new-worktree`) | ACTIVE | 4 | 4 | 4 | 5 | 4 | 43 | 86% | Worktree command for branch/plugin-scope isolation; sub-command of git-workflow-tools, not a separate plugin. `cache/.../git-workflow-tools/0.16.5/commands/gm-new-worktree.md` |
| kellerai-intent-router | ACTIVE | 3 | 2 | 3 | 5 | 4 | 33 | 66% | UserPromptSubmit hook; advisory routing only, no decision gate. `cache/.../kellerai-intent-router/1.1.0/hooks/hooks.json` |

## D6 — governance & decision-traceability

| Plugin | Tier | C1 | C2 | C3 | C4 | C5 | Raw/50 | Norm% | Rationale + citation |
|--------|------|----|----|----|----|----|--------|-------|----------------------|
| beads-workflow | ACTIVE | 4 | 3 | 5 | 5 | 5 | 46 | 92% | Beads epics + DAG encode multi-phase decisions; bridge captures issue/epic IDs. `cache/.../beads-workflow/1.14.0/skills/plan-to-beads/SKILL.md` |
| git-workflow-tools | ACTIVE | 3 | 4 | 4 | 5 | 4 | 41 | 82% | Conventional commits record WHY + issue keys; commit SHA is the decision artifact. `cache/.../git-workflow-tools/0.16.5/commands/gm-commit.md` |
| handoff-prompt-author | ACTIVE | 4 | 2 | 5 | 5 | 4 | 39 | 78% | 6 canonical handoff patterns (decision-lock, decision-centric); checklist is advisory. `cache/.../handoff-prompt-author/1.3.1/skills/handoff-prompt-author/SKILL.md` |

## #1 picks (Agent A)

- D5: **git-workflow-tools** (98%).
- D6: **beads-workflow** (92%).

## Domains with no candidates in this slice

D1, D2, D3, D4, D7 — no orchestration/workflow/git plugin fits these.

## Multi-domain plugins flagged

- `git-workflow-tools` → D5 (98%) + D6 (82%).
- `beads-workflow` → D5 (96%) + D6 (92%).
- `kellerai-orchestrator` → D5 (94%); foundational, other plugins layer on its hook dispatcher.
