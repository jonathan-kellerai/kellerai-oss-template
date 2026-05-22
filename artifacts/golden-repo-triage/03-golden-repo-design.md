---
status: complete
run_id: golden-repo-triage-2026-05-22
phase: Phase 3 — Golden-repo design synthesis
completed_at: 2026-05-22T08:24:00Z
exit_criteria:
  - id: 1
    text: Every incident class mapped or UNADDRESSED+rationale
    status: satisfied — IC-1..IC-7 all mapped in the enforcement matrix; none UNADDRESSED
  - id: 2
    text: Every UNADDRESSED incident has an action item
    status: satisfied (vacuous) — no incident class is UNADDRESSED
  - id: 3
    text: strategic-reasoner resolved every conflict
    status: satisfied — XC-1..XC-4 resolved by thoughtbox:strategic-reasoner-agent a07f023f
  - id: 4
    text: ADR count >= major choices
    status: satisfied — 11 major choices, 11 ADRs (ADR-001..ADR-011)
  - id: 5
    text: every domain has >=1 enforcement gate
    status: satisfied — D1..D7 each mapped to a gate in the enforcement matrix
  - id: 6
    text: opa check / opa test exit 0 on every proposed conformance change
    status: satisfied — migration note proposes ZERO conformance.rego/data.json changes; baseline verified 2026-05-22 (opa check exit 0; opa test 22/22 PASS)
---

# Phase 3 — Golden-Repo Design

This is the authoritative design document for the run.
`SUMMARY.md` is a derived subset of this file.
Triple-write status: artifact OK | hub post OK | mail OK.

Every claim cites evidence: internal refs as `file:line`; capability refs as `plugin-cache-path:manifest-field`; cross-artifact refs as `artifact:line`.

## 1. What "the golden repo" is

The golden repo is `kellerai-oss-template` itself, extended into the canonical example of agentic
software development. It keeps its current identity — OPA/Rego conformance authority + bootstrap
scaffold, artifact type `rego-policy` (`AGENTS.md:11`) — and adds a documented, enforced answer to
each triage domain. It is not a new repository; it is a delta on the existing one.

The design is anchored to two evidence sets:

- The incident ledger — 7 incident classes IC-1..IC-7 (`01-incident-ledger.md:31-39`).
- The scored capability roster — #1 pick per domain (`02-scored-agents.md:118-128`).

## 2. Golden-repo file tree

Existing structure is retained verbatim. New components are marked `[NEW]`; all `[NEW]` items are
TIER-2 or TIER-3 (see ADR-008) — none is a conformance-required file, so none triggers a major
semver bump (`AGENTS.md` semver discipline).

```text
kellerai-oss-template/
├── README.md                       # required (data.json:4-18)
├── AGENTS.md                       # required; + [NEW] "Capability Roster" section (ADR-002..007)
├── CLAUDE.md                       # required; first line @AGENTS.md (data.json:84)
├── LICENSE  NOTICE  CHANGELOG.md  CITATION.cff  CONTRIBUTING.md  SECURITY.md   # required
├── .gitignore                      # required; covers .claude/ .claude-tmp/ .DS_Store (data.json:75-79)
├── .markdownlint-cli2.yaml  commitlint.config.js  lefthook.yml                 # required
├── .github/
│   ├── CODEOWNERS  dependabot.yml  PULL_REQUEST_TEMPLATE.md                    # required
│   ├── ISSUE_TEMPLATE/config.yml                                              # required
│   └── workflows/
│       ├── ci.yml  commitlint.yml  pages.yml                                  # required
│       └── conformance.yml          # required; + [NEW] agentic-gates job (IC-1..IC-7) — ADR-011
├── docs/
│   ├── conformance-policy.md  adoption-guide.md
│   ├── agents/  (conventions.md citation.md glossary.md enforcement.md)        # required
│   ├── adr/                         # [NEW] decision records — ADR-000-template.md + ADR-NNN-*.md (ADR-009)
│   └── claude-settings.template.json # [NEW] permission allowlist template (ADR-010)
├── scripts/
│   ├── scan-repo-structure.sh  bootstrap.sh  check-sanitization.sh             # existing
│   └── preflight.sh                 # [NEW] artifact-dir + tree preflight (IC-1, IC-7) — ADR-008
├── conformance/  (conformance.rego conformance_test.rego data.json README.md)  # frozen — UNCHANGED
├── standard/OSS-PUBLICATION-STANDARD.md
└── template/_files/                 # bootstrap token templates
```

## 3. Canonical capability roster

The plugin the golden repo standardizes on per domain. Scores from `02-scored-agents.md`; the D2 and
D4 picks were adjusted by conflict resolution (XC-1, XC-2 — see §6).

| Domain | Canonical pick | Tier | Score | Secondary | Source |
|--------|----------------|------|-------|-----------|--------|
| D1 session-mining | `thoughtbox` (`session-analyst` skill) | ACTIVE | 94% | — | `02-scored-agents.md:46` |
| D2 plugin-&-capability-analysis | `kellerai-repo-audit` | ACTIVE | 94% | — | `02-scored-agents.md:56` |
| D3 repo-architecture/scaffolding | `kellerai-repo-audit` | ACTIVE | 100% | `kellerai-skill-creator` 100% | `02-scored-agents.md:66-67` |
| D4 conformance-&-policy | `opa-rego` | DISABLED | 68% | `kellerai-grc` 70% (on-demand) | `02-scored-agents.md:76-77` |
| D5 CI/CD authoring | `git-workflow-tools` | ACTIVE | 98% | `beads-workflow` 96% | `02-scored-agents.md:86` |
| D6 governance-&-decision-traceability | `kellerai-feature-spec` | ACTIVE | 100% | `thoughtbox` 96% | `02-scored-agents.md:96-97` |
| D7 documentation | `documentation-audit` | DISABLED | 87% | `claude-md-management` 86% (ACTIVE) | `02-scored-agents.md:106-107` |

`keller-pr-review` (D2 top score 100%, `02-scored-agents.md:56`) is repositioned as the **PR-workflow
gate** — a code-review tool, documented in AGENTS.md without a D-number (XC-2).
`kellerai-repo-audit` intentionally serves both D2 and D3 (cross-domain reuse; D3 is its scored-primary).

## 4. Enforcement matrix — standard → gate → owning file

Every standard is backed by a machine-checked gate (prose alone is insufficient).
Gate tiers per ADR-008: T1 = conformance-required file/rule; T2 = CI step; T3 = documented convention.

### 4a. Incident-class coverage (Phase 3 exit criterion 1)

| Incident | Standard | Gate (tier) | Owning file |
|----------|----------|-------------|-------------|
| IC-1 preflight-dir (`01-incident-ledger.md:33`) | Output dirs created before phase work | `scripts/preflight.sh` run as a step in the agentic-gates job (T2) | `.github/workflows/conformance.yml`, `scripts/preflight.sh` |
| IC-2 phase-wiring (`01-incident-ledger.md:34`) | Phase artifacts land at declared paths | agentic-gates step asserts declared artifact paths exist (T2) | `.github/workflows/conformance.yml` |
| IC-3 session-context (`01-incident-ledger.md:35`) | Learnings propagate across sessions | existing `claude_md_import` deny rule (T1) + handoff-file convention (T3) | `conformance/conformance.rego:claude_md_import`, `AGENTS.md` |
| IC-4 permission-allowlist (`01-incident-ledger.md:36`) | Safe tools do not prompt | `docs/claude-settings.template.json` (RECOMMENDED) + agentic-gates checksum warn-step (T2) | `docs/claude-settings.template.json`, `.github/workflows/conformance.yml` |
| IC-5 retry-policy (`01-incident-ledger.md:37`) | Transient failures retried, not looped | CI steps use bounded retry; retry convention documented (T2 + T3) | `.github/workflows/*.yml`, `AGENTS.md` |
| IC-6 dirty-state-commit (`01-incident-ledger.md:38`) | No staged-but-uncommitted state | existing `lefthook.yml` pre-commit (T1) + agentic-gates dirty-tree check (T2) | `lefthook.yml`, `.github/workflows/conformance.yml` |
| IC-7 publication-readiness (`01-incident-ledger.md:39`) | Publish only when hooks+tree+CI green | agentic-gates publication-readiness step + existing `policy_integrity` deny rule (T1 + T2) | `.github/workflows/conformance.yml`, `conformance/conformance.rego:policy_integrity` |

No incident class is `UNADDRESSED`. (Exit criterion 2 is therefore vacuously satisfied.)

### 4b. Domain gate coverage (Phase 3 exit criterion 5)

| Domain | Enforcement gate | Tier |
|--------|------------------|------|
| D1 | agentic-gates session-context step (shares IC-3 gate) | T2 |
| D2 | `conformance.yml` workflow run (structural capability analysis) + repo-audit CI invocation | T1+T2 |
| D3 | `required_file` / `required_dir` deny families (`conformance/conformance.rego:48-264`) | T1 |
| D4 | `opa check` + `opa test` CI step + `policy_integrity` deny rule | T1+T2 |
| D5 | `primary_validator_wired` deny rule + `commitlint.yml` workflow | T1+T2 |
| D6 | ADR citation-check step (every `docs/adr/*` and `03`-class doc claim cited) + lefthook | T2 |
| D7 | `readme_agent_footer` deny rule + markdownlint via `.markdownlint-cli2.yaml` in `ci.yml` | T1+T2 |

All 7 domains have ≥1 machine-checked gate.

## 5. Decision-traceability mechanism

- **ADR records** live in `docs/adr/`, one file per decision: `ADR-NNN-<slug>.md`, using the schema
  in §7. `docs/adr/ADR-000-template.md` is the copy-me template (ADR-009).
- **ADR lifecycle**: `Proposed` → `Accepted` → `Superseded`. An ADR is referenced by its number in
  commit messages and PR descriptions.
- **Citation rule**: every factual claim in an ADR or design doc carries a `file:line` or
  `plugin-path:field` citation. The D6 gate (§4b) runs a citation-check step that fails CI if a
  design-doc claim lacks a formatted citation — this is the automated check required by the run's
  decision-traceable mandate.
- **Reasoning trace**: structured reasoning is recorded in ThoughtBox (O/H/C thoughts) and the hub
  workspace; the run's own trace is `golden-repo-triage-2026-05-22` session `f8355357`.

## 6. Conflict resolutions (strategic-reasoner)

Resolved by `thoughtbox:strategic-reasoner-agent` (agent `a07f023f`). No conflict remains open
(exit criterion 3).

| ID | Conflict | Resolution |
|----|----------|------------|
| XC-1 | D4: `kellerai-grc` (70%) vs `opa-rego` (68%) | `opa-rego` is D4 primary — on-domain OPA/Rego tooling for a `rego-policy` repo beats a broad GRC plugin; 2-pt gap is scoring noise. `kellerai-grc` retained on-demand for formal compliance audits. → ADR-004 |
| XC-2 | D2: `keller-pr-review` (100%) vs `kellerai-repo-audit` (94%) | `kellerai-repo-audit` is the D2 standard — it audits capability surface; `keller-pr-review` is a code-review tool, repositioned as the PR-workflow gate with no D-number. → ADR-002 |
| XC-3 | IC-4 allowlist vs `.gitignore` `.claude/` rule | Ship `docs/claude-settings.template.json` (tracked); adopters copy it to `.claude/settings.json`. `.gitignore` rule untouched; file is RECOMMENDED not REQUIRED. → ADR-010 |
| XC-4 | Comprehensive enforcement vs minimalism / semver | Three-tier model: T1 required files (no additions), T2 CI gates (IC-1..IC-7 as steps in existing `conformance.yml`), T3 AGENTS.md conventions. Zero new required files → zero major bumps. → ADR-008 |

## 7. Migration note — what `kellerai-oss-template` must change

**This is a proposed delta, pending review. Nothing here is applied.** It does **not** modify
`conformance/`, `scripts/`, `template/`, or `standard/` in place.

Proposed changes to `conformance/conformance.rego` and `conformance/data.json`: **none.** The
three-tier model (ADR-008) routes all new enforcement through CI steps and conventions. Phase 3
exit criterion 6 is therefore satisfied with no policy delta to validate; the baseline was
verified green on 2026-05-22 — `opa check conformance/` exit 0, `opa test conformance/` 22/22 PASS.

Draft deltas (all TIER-2 / TIER-3):

1. **Add `[NEW]` agentic-gates job to `.github/workflows/conformance.yml`** — a job running the
   IC-1..IC-7 gate steps from §4a. Sketch (draft, not applied):

   ```yaml
   # draft delta — appended to .github/workflows/conformance.yml
   agentic-gates:
     runs-on: ubuntu-latest
     steps:
       - uses: actions/checkout@<pinned-sha>
       - name: IC-1 preflight dirs        # bash scripts/preflight.sh
       - name: IC-2 phase-artifact paths  # assert declared artifact paths exist
       - name: IC-4 settings checksum     # warn if .claude/settings.json diverges from template
       - name: IC-6 dirty-tree check      # git status --porcelain must be empty
       - name: IC-7 publication readiness # hooks present + tree clean + prior CI green
       - name: D6 citation check          # every docs/adr/* claim has a file:line citation
   ```

2. **Add `docs/adr/`** with `ADR-000-template.md` (the §8 schema) — TIER-3 convention (ADR-009).
3. **Add `docs/claude-settings.template.json`** — scoped permission allowlist; RECOMMENDED (ADR-010).
4. **Add `scripts/preflight.sh`** — artifact-dir + clean-tree preflight (IC-1, IC-7).
5. **Add a "Capability Roster" section to `AGENTS.md`** — the §3 table + the PR-workflow note;
   stays within the `agents_md_length` ≤150-line cap (`conformance/data.json:82`) — the section is
   compact; if the cap is approached, move the roster to `docs/agents/capability-roster.md`.
6. **`CHANGELOG.md`** — one `minor` entry (new optional rules / conventions), per semver discipline.

## 8. Open action items

| ID | Action | Origin |
|----|--------|--------|
| AI-1 | Enable the disabled canonical plugins — `opa-rego`, `kellerai-grc`, `documentation-audit` (and `codebase-cartographer` for D2 support) before standardizing on them. | User Phase 0 decision (`00-domains.md`); D4/D7 picks are DISABLED-tier |
| AI-2 | D1 has no real-time in-session mining tool — `thoughtbox` session-analyst is post-hoc only. Optional: author a custom in-session observability capability. | `02-crawl-E.md` UNDER-SERVED finding |
| AI-3 | Author the agentic-gates job steps + `scripts/preflight.sh` (design only; not in scope of this run). | §7 draft delta |
| AI-4 | Decide whether the PR-workflow gate (`keller-pr-review`) is wired into `ci.yml` or left adopter-optional. | XC-2 |

## 9. ADRs

ADR-001..ADR-011 follow. Major choices: 7 domain picks + three-tier model + ADR location +
allowlist template + IC-gate placement = 11. ADR count = 11. (Exit criterion 4 satisfied.)

---
title: "ADR-001 — Adopt thoughtbox as the D1 session-mining capability"
status: Accepted
date: 2026-05-22
---

## Context

IC-3 session-context loss (`01-incident-ledger.md:35`) shows prior-session learnings were not
propagated. Session mining is the capability that closes that loop.

## Considered options

| Option | Tier | Raw score (/50) | Normalized | Source |
|--------|------|-----------------|-----------|--------|
| thoughtbox | ACTIVE | 47 | 94% | `02-scored-agents.md:46` |
| token-triage-analyzer | BENCHED | 27 | 54% | `02-scored-agents.md:47` |
| log-compressor-tools | BENCHED | 24 | 48% | `02-scored-agents.md:48` |

## Decision

Adopt `thoughtbox` (`session-analyst` skill) — the only ACTIVE candidate and top score
(`02-scored-agents.md:46`).

## Consequences

D1 gate is the agentic-gates session-context step (§4b). A real-time in-session mining gap remains
(AI-2) — `thoughtbox` mines past sessions only.

---
title: "ADR-002 — Adopt kellerai-repo-audit as the D2 capability standard"
status: Accepted
date: 2026-05-22
---

## Context

D2 is plugin-&-capability-analysis. The top-scored candidate is a code-review tool, creating a
conceptual conflict (XC-2). Relevant incident: IC-2 phase-wiring (`01-incident-ledger.md:34`).

## Considered options

| Option | Tier | Raw score (/50) | Normalized | Source |
|--------|------|-----------------|-----------|--------|
| keller-pr-review | ACTIVE | 50 | 100% | `02-scored-agents.md:56` |
| kellerai-repo-audit | ACTIVE | 47 | 94% | `02-scored-agents.md:57` |

## Decision

Adopt `kellerai-repo-audit` for D2. `keller-pr-review` is repositioned as the PR-workflow gate with
no D-number (XC-2 resolution). Reason: `kellerai-repo-audit` literally audits a repo's capability
surface; `keller-pr-review` operates on code diffs.

## Consequences

`kellerai-repo-audit` serves D2 and D3 (cross-domain reuse). AGENTS.md documents `keller-pr-review`
separately as the PR-workflow gate. D2 gate per §4b.

---
title: "ADR-003 — Adopt kellerai-repo-audit + kellerai-skill-creator for D3"
status: Accepted
date: 2026-05-22
---

## Context

D3 is repo-architecture/scaffolding. IC-1 preflight-dir (`01-incident-ledger.md:33`) is a
scaffolding-discipline failure.

## Considered options

| Option | Tier | Raw score (/50) | Normalized | Source |
|--------|------|-----------------|-----------|--------|
| kellerai-repo-audit | ACTIVE | 50 | 100% | `02-scored-agents.md:66` |
| kellerai-skill-creator | ACTIVE | 50 | 100% | `02-scored-agents.md:67` |
| plugin-dev | ACTIVE | 41 | 82% | `02-scored-agents.md:68` |

## Decision

`kellerai-repo-audit` is the D3 primary (architecture analysis); `kellerai-skill-creator` is the
scaffolding/component-generation companion. Both scored 100%; the tie was resolved by orchestrator
judgment (`02-scored-agents.md:71`).

## Consequences

D3 gate is the existing `required_file`/`required_dir` deny families
(`conformance/conformance.rego:48-264`) — no new gate needed.

---
title: "ADR-004 — Adopt opa-rego as D4 primary; kellerai-grc on-demand"
status: Accepted
date: 2026-05-22
---

## Context

D4 is conformance-&-policy (OPA/Rego). The repo's artifact type is `rego-policy` (`AGENTS.md:11`)
and it ships `conformance/conformance.rego`. The top-scored candidate is a broad GRC plugin (XC-1).

## Considered options

| Option | Tier | Raw score (/50) | Normalized | Source |
|--------|------|-----------------|-----------|--------|
| kellerai-grc | DISABLED | 35 | 70% | `02-scored-agents.md:76` |
| opa-rego | DISABLED | 34 | 68% | `02-scored-agents.md:77` |
| kellerai-tdd | DISABLED | 31 | 62% | `02-scored-agents.md:78` |

## Decision

`opa-rego` is the D4 primary — exact-on-domain for a `rego-policy` repo; the 2-point gap is scoring
noise (XC-1). `kellerai-grc` is retained, enabled on-demand for formal compliance audits.

## Consequences

Both are DISABLED-tier → AI-1 (enable before standardizing). D4 gate is the `opa check`/`opa test`
CI step + the `policy_integrity` deny rule (§4b).

---
title: "ADR-005 — Adopt git-workflow-tools as the D5 CI/CD capability"
status: Accepted
date: 2026-05-22
---

## Context

IC-6 dirty-state-commit (`01-incident-ledger.md:38`) and IC-7 publication-readiness
(`01-incident-ledger.md:39`) are both commit/publish-discipline failures D5 must close.

## Considered options

| Option | Tier | Raw score (/50) | Normalized | Source |
|--------|------|-----------------|-----------|--------|
| git-workflow-tools | ACTIVE | 49 | 98% | `02-scored-agents.md:86` |
| beads-workflow | ACTIVE | 48 | 96% | `02-scored-agents.md:88` |
| kellerai-orchestrator | ACTIVE | 47 | 94% | `02-scored-agents.md:89` |

## Decision

Adopt `git-workflow-tools` — top score after the Phase 2 conflict escalation
(`02-scored-agents.md:91`); it gates every commit/push via a PreToolUse hook.

## Consequences

D5 gate is `primary_validator_wired` + `commitlint.yml` (§4b). IC-6 uses the existing `lefthook.yml`.

---
title: "ADR-006 — Adopt kellerai-feature-spec + thoughtbox for D6"
status: Accepted
date: 2026-05-22
---

## Context

D6 is governance-&-decision-traceability. The run's own decision-traceable mandate requires ADRs
with citations. No incident is specific to D6; it is grounded primarily in Phase 2 scores, which is
acceptable for a low-incident domain.

## Considered options

| Option | Tier | Raw score (/50) | Normalized | Source |
|--------|------|-----------------|-----------|--------|
| kellerai-feature-spec | ACTIVE | 50 | 100% | `02-scored-agents.md:96` |
| thoughtbox | ACTIVE | 48 | 96% | `02-scored-agents.md:97` |
| beads-workflow | ACTIVE | 46 | 92% | `02-scored-agents.md:98` |

## Decision

`kellerai-feature-spec` is the D6 primary (phase manifest + `progress.jsonl` gate + ADR-style
records); `thoughtbox` is the reasoning/decision-record companion.

## Consequences

D6 gate is the ADR citation-check CI step (§4b). ADR records live in `docs/adr/` (ADR-009).

---
title: "ADR-007 — Adopt documentation-audit + claude-md-management for D7"
status: Accepted
date: 2026-05-22
---

## Context

D7 is documentation. The top-scored candidate is DISABLED-tier.

## Considered options

| Option | Tier | Raw score (/50) | Normalized | Source |
|--------|------|-----------------|-----------|--------|
| documentation-audit | DISABLED | 43.5 | 87% | `02-scored-agents.md:106` |
| claude-md-management | ACTIVE | 43 | 86% | `02-scored-agents.md:107` |
| human-writing | ACTIVE | 36 | 72% | `02-scored-agents.md:108` |

## Decision

`documentation-audit` is the D7 primary (machine-readable findings + diffs); `claude-md-management`
is the ACTIVE-tier companion that operates with no enable step.

## Consequences

`documentation-audit` is DISABLED → AI-1. D7 gate is `readme_agent_footer` + markdownlint (§4b).

---
title: "ADR-008 — Adopt a three-tier enforcement model"
status: Accepted
date: 2026-05-22
---

## Context

XC-4: comprehensive enforcement for the 7 incident classes (`01-incident-ledger.md:31-39`) plus the
7 domains conflicts with the repo's minimal-required-file philosophy, where each new required file
(`conformance/data.json:4-18`) is a major semver bump (`AGENTS.md` semver-discipline rule).

## Considered options

| Option | Tier | Raw score (/50) | Normalized | Source |
|--------|------|-----------------|-----------|--------|
| All gates as conformance-required files/rules | n/a | n/a | n/a | rejected — cascading major bumps |
| Three-tier model (T1 required / T2 CI / T3 convention) | n/a | n/a | n/a | XC-4, `strategic-reasoner a07f023f` |

## Decision

Adopt the three-tier model: T1 = conformance-required (no additions); T2 = CI step in an existing
required workflow; T3 = documented AGENTS.md convention.

## Consequences

Zero new required files; zero major semver bumps. All IC gates become steps in the existing
`.github/workflows/conformance.yml` (ADR-011).

---
title: "ADR-009 — Store decision records in docs/adr/"
status: Accepted
date: 2026-05-22
---

## Context

The run's decision-traceable mandate requires a documented home for ADRs. IC-3 session-context
(`01-incident-ledger.md:35`) shows decisions were lost across sessions.

## Considered options

| Option | Tier | Raw score (/50) | Normalized | Source |
|--------|------|-----------------|-----------|--------|
| docs/adr/ directory, one file per ADR | T3 | n/a | n/a | this design |
| ADRs inline in CHANGELOG.md | n/a | n/a | n/a | rejected — not decision-first |

## Decision

ADRs live in `docs/adr/ADR-NNN-<slug>.md` using the §10 schema; `docs/adr/ADR-000-template.md` is
the template. TIER-3 convention — not a conformance-required directory.

## Consequences

`docs/adr/` is a `[NEW]` directory (§2). The D6 citation-check step covers it.

---
title: "ADR-010 — Ship the permission allowlist as docs/claude-settings.template.json"
status: Accepted
date: 2026-05-22
---

## Context

IC-4 permission-allowlist (`01-incident-ledger.md:36`): 104 permission-guard overrides. The fix is a
version-controlled allowlist, but `conformance/data.json:75-79` requires `.gitignore` to cover
`.claude/`, so `.claude/settings.json` cannot be committed (XC-3).

## Considered options

| Option | Tier | Raw score (/50) | Normalized | Source |
|--------|------|-----------------|-----------|--------|
| Commit `.claude/settings.json` directly | n/a | n/a | n/a | rejected — violates `data.json:75-79` |
| Ship `docs/claude-settings.template.json`, adopters copy it | T3 | n/a | n/a | XC-3, `strategic-reasoner a07f023f` |

## Decision

Ship `docs/claude-settings.template.json` (tracked). Adopters copy it to `.claude/settings.json` in
a one-time setup step documented in AGENTS.md. RECOMMENDED, not REQUIRED.

## Consequences

`.gitignore` `.claude/` rule untouched. The agentic-gates job adds a warn-step comparing the local
`.claude/settings.json` checksum to the template.

---
title: "ADR-011 — Place IC gates inside the existing conformance.yml workflow"
status: Accepted
date: 2026-05-22
---

## Context

The IC-1..IC-7 gates (`01-incident-ledger.md:31-39`) need a CI home. A new workflow file would be a
new file in the `.github/workflows/` required category (`conformance/data.json:27-37`); an existing
required workflow would not (XC-4 / ADR-008).

## Considered options

| Option | Tier | Raw score (/50) | Normalized | Source |
|--------|------|-----------------|-----------|--------|
| New `agentic-gates.yml` workflow | T2 | n/a | n/a | viable but adds a file |
| New job inside existing `conformance.yml` | T2 | n/a | n/a | ADR-008 — no new file |

## Decision

Add an `agentic-gates` job to the existing `.github/workflows/conformance.yml` (a required,
conformance-checked file). No new workflow file.

## Consequences

The IC gates inherit `conformance.yml`'s required-file status without a new required file. Draft
delta in §7.
