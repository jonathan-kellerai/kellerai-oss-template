---
status: complete
run_id: golden-repo-triage-2026-05-22
phase: Phase 2 — Marketplace crawl & scoring
completed_at: 2026-05-22T08:12:00Z
---

# Phase 2 — Scored Capability Roster

Triple-write status: artifact OK | hub post OK | mail OK.
Scored against the frozen `AGENT-SKILL-INDEX.md` snapshot (digest `c33d65da…`, see `00-domains.md`).

## WARNING — execution deviations (instruction-hierarchy rule)

Two prompt instructions could not be executed literally; both are logged here per the rule
"log the contradiction as a WARNING in the nearest relevant artifact."

1. **Phase 2 file reservation skipped.** `mail_file_reservation_paths` rejects absolute and
   out-of-project paths; the plugin cache (`~/.claude/plugins/cache/**`) is outside the repo
   root, so it cannot be reserved. The crawl is strictly read-only and no other agent writes
   the cache, so the advisory lease is moot — correctness is unaffected.
2. **Crawl artifacts authored by main chat, not subagents.** The prompt says each Explore
   agent writes its own `02-crawl-<X>.md`. The `Explore` agent type has no `Write` tool, so
   the 5 agents returned structured reports and the orchestrator (`GoldenHarbor`) wrote
   `02-crawl-A..E.md` and this file. The prompt's intent — heavy reading delegated, main chat
   owns hub/mail and context discipline — is fully preserved. No subagent called hub or mail.

## Crawl coverage

| Agent | Slice | Plugins crawled | Artifact |
|-------|-------|-----------------|----------|
| A | orchestration / workflow / git | 5 | `02-crawl-A.md` |
| B | code-analysis / review / conformance / policy | 9 | `02-crawl-B.md` |
| C | repo-scaffolding / docs / template / CI | 11 | `02-crawl-C.md` |
| D | reasoning / planning / spec / decision-trace | 10 | `02-crawl-D.md` |
| E | session / telemetry / memory / observability | 6 | `02-crawl-E.md` |

All 5 agents returned their `02-crawl-<X>.md` report — no `CRAWL-GAP`, no re-dispatch needed.
No domain produced zero candidates — there is no `UNDER-SERVED` domain (D1's gap is partial; see D1).

## Scoring protocol

Rubric (each criterion 0–5): C1 fit ×3, C2 enforceability ×3, C3 decision-traceability ×2,
C4 maturity ×1, C5 orchestration-friendliness ×1. Raw weighted total max 50; normalized = raw/50.
Tiers: ACTIVE (full weight), DISABLED (C4–C5 `(manifest-only)` at 50%), BENCHED (C4–C5 = 0).

## Ranked roster per domain

### D1 — session-mining / log-analysis

| Rank | Plugin | Tier | Raw/50 | Norm | Rationale (citation) |
|------|--------|------|--------|------|----------------------|
| 1 | **thoughtbox** | ACTIVE | 47 | 94% | `session-analyst` skill mines past sessions, extracts patterns/learnings/fitness signals (`cache/.../thoughtbox/0.29.0/skills/session-analyst/SKILL.md`). |
| 2 | token-triage-analyzer | BENCHED | 27 | 54% | Session-level telemetry mining; not installed (`cache/.../token-triage-analyzer/1.5.2/.claude-plugin/plugin.json`). |
| 3 | log-compressor-tools | BENCHED | 24 | 48% | Post-hoc debug-log / transcript compression + failure mining; not installed (`cache/.../log-compressor-tools/1.5.1/.claude-plugin/plugin.json`). |

**#1 pick: thoughtbox.** Caveat: real-time in-session pattern discovery is absent — Phase 3 action item.

### D2 — plugin-&-capability-analysis

| Rank | Plugin | Tier | Raw/50 | Norm | Rationale (citation) |
|------|--------|------|--------|------|----------------------|
| 1 | **keller-pr-review** | ACTIVE | 50 | 100% | ThoughtBox pre-analysis + 4 parallel specialist agents; diff-validated, machine-gated findings (`cache/.../keller-pr-review/0.57.0/plugin.json`). |
| 2 | kellerai-repo-audit | ACTIVE | 47 | 94% | Multi-wave capability/architecture audit with OPA gates (`cache/.../kellerai-repo-audit/1.3.0/plugin.json`). |
| 3 | log-compressor-tools | BENCHED | 17 | 34% | Hook-pattern / MCP-status introspection; tangential (`cache/.../log-compressor-tools/1.5.1`). |

**#1 pick: keller-pr-review.** Orchestrator note: keller-pr-review analyses *code/PRs*; for analysis of *plugin/agent capability* specifically, kellerai-repo-audit (94%) is the closer literal fit — Phase 3 ADR weighs this.

### D3 — repo-architecture / scaffolding

| Rank | Plugin | Tier | Raw/50 | Norm | Rationale (citation) |
|------|--------|------|--------|------|----------------------|
| 1 | **kellerai-repo-audit** | ACTIVE | 50 | 100% | 6-wave architecture audit + roadmap scaffolding; OPA-enforced; per-wave artifacts (`cache/.../kellerai-repo-audit/1.4.0/.claude-plugin/plugin.json`). Conflict-resolved to D3 (see log). |
| 2 | kellerai-skill-creator | ACTIVE | 50 | 100% | Scaffolds skills as repo components; OPA conformance enforcement; emits grading.json (`cache/.../kellerai-skill-creator/2.1.1/.claude-plugin/plugin.json`). |
| 3 | plugin-dev | ACTIVE | 41 | 82% | Scaffolds plugins/skills/commands/agents; guidance-focused (`cache/claude-plugins-official/plugin-dev/.claude-plugin/plugin.json`). |
| 4 | frontend-mobile | ACTIVE | 40 | 80% | Component/UI/design-system scaffolding; tangential (`cache/.../frontend-mobile/2.7.1/.claude-plugin/plugin.json`). |

**#1 pick: kellerai-repo-audit.** Tiebreak with kellerai-skill-creator (both 100%, both C1=5, both ACTIVE) resolved by orchestrator: repo-audit is the broader repo-architecture tool (audits structure *and* seeds roadmap); skill-creator is the scaffolding-specific #2.

### D4 — conformance-&-policy (OPA/Rego)

| Rank | Plugin | Tier | Raw/50 | Norm | Rationale (citation) |
|------|--------|------|--------|------|----------------------|
| 1 | **kellerai-grc** | DISABLED | 35 | 70% | Graduated GRC enforcement incl. `/grc` blocking gate; Z3 formal verification; Rego/OPA validation (`cache/.../kellerai-grc/0.8.1/agents/grc-pack-validator-agent.md`). |
| 2 | opa-rego | DISABLED | 34 | 68% | OPA/Rego authoring, testing, linting; SARIF 2.1.0 reporter (`cache/.../opa-rego/0.3.1/agents/rego-sarif-reporter-agent.md`). |
| 3 | kellerai-tdd | DISABLED | 31 | 62% | Graduated TDD coaching with `/tdd` blocking gates (`cache/.../kellerai-tdd/0.15.1/plugin.json`). |

**#1 pick: kellerai-grc** (DISABLED). Orchestrator note: for OPA/Rego authoring *specifically* (this repo's `conformance.rego` artifact type), `opa-rego` (68%) is the on-domain tool; Phase 3 ADR weighs grc-vs-opa-rego. Per the user's Phase 0 decision, all three are recommended for enabling in the migration note.

### D5 — CI/CD authoring

| Rank | Plugin | Tier | Raw/50 | Norm | Rationale (citation) |
|------|--------|------|--------|------|----------------------|
| 1 | **git-workflow-tools** | ACTIVE | 49 | 98% | 5 commands gate every commit/push via `git_commit_guard.py` PreToolUse hook; `/gm-full` enforces commitlint + ubs + version-artifact checks (`cache/.../git-workflow-tools/0.16.5/README.md`). Escalated to #1 (see conflict log). |
| — | kellerai-repo-audit | ACTIVE | 50 | 100% | Won D5 on raw score but conflict-routed to D3; detects CI/CD gaps, does not author CI/CD. |
| 2 | beads-workflow | ACTIVE | 48 | 96% | Converts plans/specs/alerts into beads epics with DAG dependencies (`cache/.../beads-workflow/1.14.0/agents/bridge-orchestrator-agent.md`). |
| 3 | kellerai-orchestrator | ACTIVE | 47 | 94% | Single dispatcher over 13 hook events; capabilities return block/allow/warn (`cache/kellerai-hooks/kellerai-orchestrator/1.7.2/CLAUDE.md`). |
| 4 | tdd-workflow | BENCHED | 27 | 54% | Test-first CI/CD workflow; not installed. |

**#1 pick: git-workflow-tools** (escalated after kellerai-repo-audit routed to D3).

### D6 — governance-&-decision-traceability (ADR / spec)

| Rank | Plugin | Tier | Raw/50 | Norm | Rationale (citation) |
|------|--------|------|--------|------|----------------------|
| 1 | **kellerai-feature-spec** | ACTIVE | 50 | 100% | Multi-phase spec polish; phase manifest + `progress.jsonl` gate; pre/post-phase versioning + snapshots; ADR-style decision records (`cache/.../kellerai-feature-spec/0.17.1/agents/spec-orchestrator-agent.md`). |
| 2 | thoughtbox | ACTIVE | 48 | 96% | Structured reasoning with mental models, branching, mandatory critique loops; decision artifacts via knowledge graph (`cache/.../thoughtbox/0.29.0/agents/strategic-reasoner-agent.md`). Agent E scored the same plugin 98% on its knowledge-graph skill. |
| 3 | beads-workflow | ACTIVE | 46 | 92% | Beads epics + DAG encode multi-phase decisions (`cache/.../beads-workflow/1.14.0/skills/plan-to-beads/SKILL.md`). |
| 4 | git-workflow-tools | ACTIVE | 41 | 82% | Conventional commits record WHY + issue keys; commit SHA is the decision artifact. |
| 5 | handoff-prompt-author | ACTIVE | 39 | 78% | 6 canonical handoff patterns (decision-lock, decision-centric). |
| 6 | kellerai-grc | DISABLED | 31 | 62% | Z3-verified compliance decision records. |
| 7 | exec-summary | DISABLED | 25 | 50% | PDF executive-summary with OPA/Rego layout enforcement. |

**#1 pick: kellerai-feature-spec.**

### D7 — documentation

| Rank | Plugin | Tier | Raw/50 | Norm | Rationale (citation) |
|------|--------|------|--------|------|----------------------|
| 1 | **documentation-audit** | DISABLED | 43.5 | 87% | 6-agent doc audit; P0-P3 severity + machine-readable JSON findings + ready-to-apply diffs (`cache/.../documentation-audit/0.13.1/.claude-plugin/plugin.json`). |
| 2 | claude-md-management | ACTIVE | 43 | 86% | Audits/scaffolds CLAUDE.md; quality-score rubric; targeted diffs (`cache/claude-plugins-official/claude-md-management/1.0.0/.claude-plugin/plugin.json`). Top ACTIVE-tier pick. |
| 3 | human-writing | ACTIVE | 36 | 72% | Removes AI-writing patterns; pattern-detection rules (`cache/.../human-writing/2.4.1/.claude-plugin/plugin.json`). |
| 4 | keller-render | ACTIVE | 34 | 68% | Design-system + WeasyPrint PDF/HTML rendering; support role (`cache/.../keller-render/1.1.0/.claude-plugin/plugin.json`). |
| 5 | cli-skills | DISABLED | 18 | 36% | CLI routing/reference; low fit. |
| 6 | remember | BENCHED | 15 | 30% | Cross-session handoff note; memory persistence, not documentation. |

**#1 pick: documentation-audit** (DISABLED). Top ACTIVE-tier alternative: claude-md-management (86%).

## Conflict-resolution log

| Conflict | Resolution |
|----------|------------|
| `kellerai-repo-audit` scored #1 in both D3 (100%) and D5 (100%). | Conflict rule applied. D3 and D5 tied on raw score and C1 (both 5). Orchestrator routed it to **D3** — its criterion-1 fit is intrinsically repository-architecture/audit; for D5 it *detects* CI/CD gaps but does not *author* CI/CD. D5's #2 (`git-workflow-tools`, 98%) escalated to D5 #1. |
| D3 internal tie: `kellerai-repo-audit` vs `kellerai-skill-creator`, both 100%. | Not a multi-domain conflict (two plugins, one domain). Tiebreak (C1, then tier) inconclusive; resolved by orchestrator judgment — repo-audit #1 (broader), skill-creator #2. Both retained. |
| `git-workflow-tools` D5 score differs by agent: A=98%, C=90%. | Master uses Agent A's 98% — git-workflow-tools is squarely in Agent A's (orchestration/git) slice. |
| `thoughtbox` D6 score differs by agent: D=96%, E=98%. | Master uses Agent D's 96% (D6 is Agent D's home slice); E's 98% noted. Does not change ranking — kellerai-feature-spec 100% is D6 #1 either way. |

No plugin is the #1 pick for more than one domain after resolution.

## Cross-domain plugins (reference)

- `kellerai-repo-audit` → D2, D3, D5 (#1 in D3).
- `thoughtbox` → D1 (#1), D6.
- `git-workflow-tools` → D5 (#1), D6.
- `beads-workflow` → D5, D6.
- `kellerai-grc` → D4 (#1), D6.
- `kellerai-feature-spec` → D6 (#1), D3.

## Disabled-plugin note (Phase 0 user decision)

Per the user's Phase 0 decision, the disabled domain-critical plugins were scored from manifest
(DISABLED tier) **and** are recommended for enabling in the Phase 3 migration note:
`opa-rego` (D4, 68%), `kellerai-grc` (D4 #1, 70%), `kellerai-tdd` (D4, 62%), `codebase-cartographer`
(not surfaced as a domain #1; D2-adjacent). `documentation-audit` (D7 #1, 87%) is also DISABLED and
likewise carries an enable recommendation.

## Phase 2 exit summary

| Domain | #1 pick | Tier | Norm |
|--------|---------|------|------|
| D1 session-mining | thoughtbox | ACTIVE | 94% |
| D2 plugin-&-capability-analysis | keller-pr-review | ACTIVE | 100% |
| D3 repo-architecture/scaffolding | kellerai-repo-audit | ACTIVE | 100% |
| D4 conformance-&-policy | kellerai-grc | DISABLED | 70% |
| D5 CI/CD authoring | git-workflow-tools | ACTIVE | 98% |
| D6 governance-&-decision-traceability | kellerai-feature-spec | ACTIVE | 100% |
| D7 documentation | documentation-audit | DISABLED | 87% |

All 7 domains served. 2 of 7 #1 picks are DISABLED-tier (D4, D7) → carried into the Phase 3 migration note as enable recommendations.
