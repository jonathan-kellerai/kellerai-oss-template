---
status: complete
run_id: golden-repo-triage-2026-05-22
phase: Phase 1 — Session mining
completed_at: 2026-05-22T07:58:00Z
---

# Phase 1 — Incident Ledger

Date: 2026-05-22.
Triple-write status: artifact OK | hub post OK | mail OK.

## Corpus header

| Transcript | Lines | Parsed OK | Unparseable | Status |
|------------|-------|-----------|-------------|--------|
| `47eaaeb9-1121-4757-9184-c7e2691658e5.jsonl` | 983 | 983 | 0% | CLEAN |
| `f1a24ca8-6162-419b-b60d-01950eb007ba.jsonl` | 2094 | 2094 | 0% | CLEAN |

Total lines analysed: 3077.
Files flagged `CORRUPT` and skipped: 0.
All extracted content was sanitised (no secrets present) and user message content paraphrased, not quoted.

## Sparse-corpus note

The corpus is two transcripts (3077 lines).
It yields **7 incident classes** — above the 5-incident floor, so Phase 3 ADRs may be grounded in Phase 1 evidence.
The corpus is small and specific: both transcripts cover the prompt-critique and orchestration of *this* run, not a broad sample of agentic development.
Phase 3 should weight Phase 2 capability scores alongside this evidence rather than relying on Phase 1 alone.

## Incidents — evidence → root cause → would-be standard/gate

| ID | Evidence (`file:line`) | Root cause | Would-be standard / gate |
|----|------------------------|------------|--------------------------|
| IC-1 | `f1a24ca8.jsonl:1616` | A multi-phase run referenced its output directory before creating it. | A mandatory `mkdir -p` preflight step, plus a conformance/CI check that declared output directories exist before phase work begins. |
| IC-2 | `f1a24ca8.jsonl:1539`–`1721` | No executor wires phase N output → phase N+1 input; phase results sat siloed in `/tmp` and were fetched by hand. | A declared artifact-path convention and phase manifest, enforced by a CI check that every phase artifact lands at its declared path. |
| IC-3 | `f1a24ca8.jsonl:1993`, `f1a24ca8.jsonl:2002` | Inter-session context loss — prior-session learnings and setup were not propagated; the user re-supplied context. | A required learnings/handoff file and a `CLAUDE.md` `@import` directive (already partly enforced by the `claude_md_import` deny rule). |
| IC-4 | `47eaaeb9.jsonl` (30×), `f1a24ca8.jsonl` (74×) | Tooling over-guards safe and read-only operations; 104 permission-mode overrides were needed. | A scoped, checked-in `.claude/settings.json` allowlist for safe tool categories, so approval is required only for write/destructive ops. |
| IC-5 | `47eaaeb9.jsonl` (3×), `f1a24ca8.jsonl` (3×) | Transient task failures had no retry/backoff; 6 rework loops needed manual re-invocation. | A documented retry policy, CI steps with bounded retry, and fail-fast errors that surface a remediation message instead of looping. |
| IC-6 | `47eaaeb9.jsonl:6` | A staged file (`scripts/publish.sh`) was never committed; a pre-commit hook then blocked an amend. | A lefthook pre-commit gate plus a zero-dirty-state check, both emitting clear remediation text. |
| IC-7 | `47eaaeb9.jsonl:6` | A publication kickoff began without verifying hooks, staged files, or CI status. | A publication-readiness checklist as a CI workflow / conformance rule: hooks validated, tree clean, CI green. |

## Decisions

| Evidence (`file:line`) | Decision | Why it won |
|------------------------|----------|------------|
| `47eaaeb9.jsonl` (kickoff) | Sequential repo publishing — `kellerai-oss-template` first, then siblings. | Explicit ordering embedded in the kickoff task; one repo is the conformance authority and must publish first. |
| `f1a24ca8.jsonl` (git workflow) | `gm-full` audited git workflow chosen over `gm-commit` / `gm-push`. | The change touched plugin/CI files (risky tier), which routes to full-audit mode. |

No `AskUserQuestion` decisions with competing options were recovered from the corpus; the decisions above were embedded workflow choices.

## Manual steps that should be gates

These reinforce the incident table — each is a hand-run step that a golden repo should automate.

- Pre-creating artifact directories (IC-1).
- Wiring phase outputs to the next phase's inputs (IC-2).
- Restoring session context and learnings (IC-3).
- Committing staged files before a publication run (IC-6).

## Friction

- **Permission-guard overhead (IC-4):** 104 permission-mode overrides across 3077 lines — the dominant friction signal; the ratio of guard-stalls to incidents is roughly 15:1.
- **Rework loops (IC-5):** 6 manual re-invocations after transient failures.
- No RTFM-class misses (acting on an unverified flag) were positively identified in the corpus.

## Incident-class index (for Phase 3 traceability)

IC-1 preflight-dir, IC-2 phase-wiring, IC-3 session-context, IC-4 permission-allowlist, IC-5 retry-policy, IC-6 dirty-state-commit, IC-7 publication-readiness.
Phase 3 must map every IC-n to an enforcement gate or mark it `UNADDRESSED` with a rationale.
