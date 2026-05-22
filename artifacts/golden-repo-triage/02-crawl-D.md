---
status: complete
run_id: golden-repo-triage-2026-05-22
phase: Phase 2 — Marketplace crawl (Agent D)
completed_at: 2026-05-22T08:10:00Z
---

# Phase 2 — Crawl Agent D: reasoning / planning / spec / decision-trace

Authored by orchestrator `GoldenHarbor` from Crawl Agent D's returned report (Explore agents have no Write tool — see WARNING in `02-scored-agents.md`).
Slice: structured reasoning, planning, spec/ADR, decision-trace plugins. 10 plugins crawled.

## D6 — governance & decision-traceability (ADR / spec)

| Plugin | Tier | C1 | C2 | C3 | C4 | C5 | Raw/50 | Norm% | Rationale + citation |
|--------|------|----|----|----|----|----|--------|-------|----------------------|
| kellerai-feature-spec | ACTIVE | 5 | 5 | 5 | 5 | 5 | 50 | 100% | Multi-phase spec polish; phase manifest + `progress.jsonl` gate enforcement; pre/post-phase versioning + snapshots; ADR-style decision records; Mail/Hub-registered orchestrator. `cache/.../kellerai-feature-spec/0.17.1/agents/spec-orchestrator-agent.md` |
| thoughtbox | ACTIVE | 5 | 4 | 5 | 5 | 5 | 48 | 96% | Structured reasoning with mental models, branching, mandatory C-type critique loops; session recording + extraction; Hub/Mail aware. `cache/.../thoughtbox/0.29.0/agents/strategic-reasoner-agent.md` |
| kellerai-grc | DISABLED | 5 | 5 | 4 | 2 | 2 | 31 | 62% | Z3 formal verification of compliance policies; graduated enforcement; agents emit formal verification reports. `cache/.../kellerai-grc/0.8.1/agents/grc-z3-verifier-agent.md` |
| exec-summary | DISABLED | 3 | 4 | 5 | 2 | 1 | 25 | 50% | PDF executive-summary generation with OPA/Rego layout enforcement; template registry. `cache/.../exec-summary/1.17.0/plugin.json` |
| research-to-prd | DISABLED | 3 | 2 | 3 | 2 | 1 | 16 | 32% | PRD/TRD production from research; shallow manifest. |
| whitepaper-quest | DISABLED | 3 | 2 | 2 | 2 | 3 | 16 | 32% | P-series quest orchestration via ThoughtBox Hub + Agent Mail; planning, not decision-trace. |
| agent-evolution-framework | DISABLED | 3 | 3 | 2 | 2 | 2 | 15 | 30% | Codebase pattern extraction → KOTH-tracked components; tangential. |
| whitepaper-studio | DISABLED | 3 | 2 | 3 | 2 | 1 | 15 | 30% | Whitepaper workflow; D7-leaning, not D6. |
| agent-creator | DISABLED | 2 | 2 | 2 | 2 | 2 | 12 | 24% | Agent creation + evals; not reasoning/spec. |
| cross-discipline-research | DISABLED | 2 | 1 | 2 | 1 | 1 | 8 | 16% | Research synthesis; tangential. |

## #1 pick (Agent D)

- D6: **kellerai-feature-spec** (100%).

## Multi-domain plugins flagged

- `thoughtbox` → D6 + D1 (session extraction, learnings API).
- `kellerai-feature-spec` → D6 + D3 (phase manifests scaffold spec workflow structure).
- `kellerai-grc` → D6 + D4 (decision records + OPA/Rego enforcement).

All plugin.json files in this slice were found and readable; no manifest-read failures.
