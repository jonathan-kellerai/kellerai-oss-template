# OSS Publication Standard

Decisions ratified during the **dgm-telemetry** Phase 3 finalization session on
2026-05-21. They apply to **all six** repositories staged under `~/oss-staging/`:

- `aegis-drop`
- `dgm-telemetry`
- `limen-spec`
- `matryoshka-spec`
- `opa-rego-patterns`
- `sentinel-rag`

**For other in-flight sessions:** treat every decision below as ratified. Do
**not** re-prompt the user on any of these. Where a decision is artifact-type
specific, the **principle is fixed** — only the **concrete tool** adapts to the
repo (a JSON-Schema repo validates with `ajv`; an OPA/Rego repo with
`opa fmt` / `opa test` / `conftest`; a spec-doc repo with structural checks).

---

## 0. Repository identity

- **Owner:** `jonathan-kellerai` (GitHub). Every repo is **public**.
- **Repo slug:** the staging directory name (`jonathan-kellerai/<dir-name>`).
- **Git author identity:** `Jonathan Bowe <jonathan-kellerai@users.noreply.github.com>`.
- **License:** per-repo — Apache-2.0, CC-BY-4.0, or MIT depending on the repository.
  Each repo carries a verbatim `LICENSE` file plus a `NOTICE` file.
- **Default branch:** `main`. `master` is forbidden.
- **Publication shape:** fresh `git init`, **one** initial commit, **one** push.
  No force-push, no rebase. One optional follow-up commit for the CHANGELOG.
  Tag `v0.1.0`. The repo's first state on GitHub must equal the intended public
  artifact exactly.

## 1. Human-vs-agent file split (every repo)

- `README.md` — humans only; ends with a short "For agents" footer pointing at
  `AGENTS.md` and `CLAUDE.md`.
- `AGENTS.md` — Tier-1 agent entry point, ≤ 150 lines: purpose, what the repo
  is / is NOT, file layout + reading order, conventions, open questions,
  Tier-2 pointers.
- `CLAUDE.md` — Claude-specific, ≤ 80 lines. First content line is the import
  `@AGENTS.md`, then Claude-only notes.
- `docs/agents/` — Tier-2 deep files: `conventions.md`, `citation.md`,
  `glossary.md`, `enforcement.md`.

## 2. Continuous integration — `.github/workflows/ci.yml`

Runs on `push` and `pull_request`, `ubuntu-latest`, with **action versions
pinned to a commit SHA**. Core gates:

- **Primary artifact validation** — the repo's canonical correctness gate.
  dgm-telemetry: `ajv compile` on every schema + `ajv validate` on every
  example. Other repos substitute the equivalent validator for their artifact.
- **JSON well-formedness** — `jq . <file> >/dev/null` on every JSON file.
- **Markdown lint** — `markdownlint-cli2 "**/*.md"` with a lenient
  `.markdownlint-cli2.yaml` (disable MD013 line-length so existing wide tables
  and frozen docs pass).
- **Sanitization regression gate** — see §3.

Extras (both ON): **link checking** (lychee) and a **GitHub Pages deploy**
(`pages.yml`, see §14).

## 3. Sanitization regression gate — leak-safe

A single shared script (`scripts/check-sanitization.sh`) holds the
internal-term denylist **base64-encoded**, decodes it at runtime, and greps the
tree. Rationale: a plaintext denylist in a workflow file would itself republish
the very strings it exists to keep out, and would be GitHub-code-search
indexed. Base64 fully closes that gap. Both CI and the pre-commit hook call this
one script; it **fails the build** on any match. Each repo's denylist is the
set of internal terms removed during that repo's prior sanitization pass.

## 4. Commit messages

- **Conventional Commits:** `<type>(<scope>): <subject>` — subject ≤ 50 chars,
  imperative mood. Types: `feat`, `fix`, `chore`, `docs`, `refactor` (+ `revert`,
  `test`, `build`, `perf`, `ci` as needed).
- **Validation: HARD** — `commitlint` **fails CI** on any non-conforming
  message. Config in a root `commitlint.config.js` (discoverable; lets
  contributors lint locally) plus a `.github/workflows/commitlint.yml`.

## 5. Branch naming and contributor governance

**4-tier branch model (all kellerai OSS repos):**

```text
external/<type>-<ISSUE-KEY>-<scope>-<gerund>-p<N>
        ↓  PR + validate-branch-name + validate-linked-issue
      dev
        ↓  PR + validate-branch-tier
       qa
        ↓  PR + squash-only + CODEOWNER review + all gate checks
      main
```

**Internal maintainers (CODEOWNERS):** use the standard kellerai convention (unchanged):
`<type>/<ISSUE-KEY>-<scope>-<gerund>` — e.g. `feat/ABC-123-auth-adding-oauth`

**External contributors:** prepend `external/` and append a priority suffix:
`external/<type>-<ISSUE-KEY>-<scope>-<gerund>-p<N>` — e.g. `external/feat-ABC-123-auth-adding-oauth-p1`

Allowed `<type>` values: `feat fix chore docs refactor test ci build perf revert style hotfix spike wip release rnd`

Priority: `p0`=critical · `p1`=high · `p2`=medium · `p3`=low · `p4`=backlog (maps to the kellerai P0–P4 severity scale).

**Three required gate workflows** (wired as required status checks):

- `.github/workflows/validate-branch-name.yml` — RE2 regex enforcement at PR open
- `.github/workflows/validate-branch-tier.yml` — tier-source restriction (main←qa←dev←external)
- `.github/workflows/validate-linked-issue.yml` — issue must be Open + have `codeowner-approved` label

**Four GitHub Rulesets** complete the enforcement: `protect-main` (squash-only, CODEOWNER review, deletion + force-push blocked), `protect-qa`, `protect-dev`, and `restrict-external-naming` (RE2 regex at branch-creation time). Full `gh api` commands and Linear integration instructions: `docs/branch-governance.md`.

**Convention edge-case review (required per repo):** each finalizing session must document the logical-but-usually-unlisted cases that cause agent errors in `docs/agents/conventions.md` — e.g. working on `main` / detached HEAD, multi-scope changes, `<scope>` kebab-casing, revert/hotfix branches, continuing another agent's branch, worktrees, the always-base-off-`main` rule, fork vs same-repo PRs, the commit `type` for CHANGELOG / CI / agent-doc edits, imperative mood with no trailing period, body wrap at 72 chars.

## 6. Pre-commit hook

- **Lefthook-managed** — a committed `lefthook.yml`; contributors install via
  `lefthook install`. The hook runs the primary artifact validation (§2) plus
  the §3 sanitization script.

## 7. Issue templates — `.github/ISSUE_TEMPLATE/*.yml` (YAML forms)

Four structured templates. Theme the artifact noun to the repo (dgm-telemetry
uses "schema"; substitute "policy", "spec", etc. as appropriate):

- `<artifact>-bug.yml` — the artifact is wrong or contradicts the docs.
- `<artifact>-clarification.yml` — an artifact element is ambiguous.
- `<artifact>-amendment-proposal.yml` — propose a new element; captures semver
  impact and rationale.
- `integration-question.yml` — how to adopt / wire in the artifact.

## 8. PR template — `.github/PULL_REQUEST_TEMPLATE.md`

Artifact-aware, five sections: **Summary** / **Artifacts touched** /
**Validation output** / **Semver classification** (major · minor · patch) /
**Contributor** (checkbox: "I am an agent acting on behalf of `<handle>`").

## 9. CODEOWNERS — `.github/CODEOWNERS`

**Sensitive-only.** Lock `.github/`, `LICENSE`, `NOTICE`, `AGENTS.md`,
`CLAUDE.md`, and each repo's foundational artifacts (dgm-telemetry:
`schemas/base/`, `schemas/goals/`) to `@jonathan-kellerai`. Leaf / tool-level
artifacts stay open.

## 10. `.github/` extras

- `dependabot.yml` — **YES**, `github-actions` ecosystem only (no runtime deps).
- `CODE_OF_CONDUCT.md` — **NO** (dropped).
- `FUNDING.yml` — **NO**.

## 11. CITATION.cff — YES

Root `CITATION.cff`, Citation File Format **1.2.0**: `title`, `authors`
(Jonathan A. Bowe), `version`, `date-released`, `license: Apache-2.0`,
`repository-code`, `keywords`. Verify the schema against
`https://citation-file-format.github.io/` — do not invent fields.
`docs/agents/citation.md` documents usage + a BibTeX template.

## 12. SECURITY.md — YES

Covers how to report a defect that could leak PII if naively implemented (e.g.
an identifier field that should be hashed). Channel: GitHub Security Advisories.
Scope: this repo only, not downstream consumers.

## 13. CONTRIBUTING.md — EXPAND

Keep existing content (issue conventions, PR checklist, validation workflow,
semver policy). **Add** a short contributor-friendly section plus explicit
pointers to `AGENTS.md` and `docs/agents/`.

## 14. GitHub Pages — `.github/workflows/pages.yml` (ON)

Publishes `docs/`. Where a repo has a whitepaper, move the whitepaper
**markdown only** (not the PDF) out of `.claude-tmp/` into the publishable
`docs/` tree first — **and only after it passes the §15 IP-leak audit**. Verify
the current `actions/deploy-pages` / Jekyll workflow syntax against GitHub docs
before writing `pages.yml`; do not invent it from memory.

## 15. IP-leak audit — MANDATORY before publish

The three-regex sanitization gate (§3) is necessary but **not sufficient**.
Every repo's docs — especially any **tool-generated** artifact (codebase atlas,
dependency map, auto-generated reference) — must get a **qualitative** IP-leak
audit covering: internal commit hashes and commit messages, internal tooling
names, absolute filesystem paths, internal URLs / hosts, contributor identity
beyond the public owner, internal codenames, architecture detail beyond the
public docs.

**Precedent (dgm-telemetry):** `docs/codebase-atlas.html` passed all three regex
gates but embedded an "Evolution" widget with private-repo git history (commit
hashes + a commit message naming internal tooling). Decision: the file was
**excluded** from publication (gitignored, kept on disk). Apply the same
scrutiny to every repo's generated artifacts.

## 16. README accuracy

Frozen READMEs may still be patched for **factual accuracy** — wrong counts,
phantom file paths, stale status tables. Accuracy fixes are in-scope even for
files otherwise declared "frozen" by a prior critique pass.

## 17. Single-commit publication procedure

1. Confirm `.gitignore` covers `.claude/`, `.claude-tmp/`, staging notes,
   kickoff prompts, `.DS_Store`, `.ruff_cache/`, and any artifact excluded by
   the §15 audit.
2. `git init`; stage the publishable tree only; verify `git status -s` shows
   no staging files.
3. One commit: `feat: publish v0.1.0 <repo> schemas and docs` (adapt subject).
4. `gh repo create jonathan-kellerai/<repo> --public --license=apache-2.0 --source=. --push`.
5. Optional follow-up commit: replace `## [Unreleased]` in `CHANGELOG.md` with
   `## [0.1.0] — <date> — Initial public release`.
6. Tag `v0.1.0` and push the tag.
7. Post-push: verify the repo is public, License auto-detected as Apache-2.0,
   README renders, topics set.

---

## Appendix — dgm-telemetry session resume state (2026-05-21)

`dgm-telemetry` Phase 3 is **paused** mid-flow. Completed:

- **Phase A:** `AGENTS.md` (99 lines), `CLAUDE.md` (34 lines),
  `docs/agents/glossary.md` (111 lines) authored; `README.md` agent footer
  added; `.gitignore` extended with `.claude-tmp/`; sanitization re-scan clean.
- **Phase B:** interview complete — all decisions above.

Remaining for dgm-telemetry (Phase C / D / E), per the decisions above:

- `docs/agents/conventions.md`, `citation.md`, `enforcement.md` (Tier-2 files).
- `.github/` — `ci.yml`, `pages.yml`, `commitlint.yml`, 4 issue templates,
  `PULL_REQUEST_TEMPLATE.md`, `CODEOWNERS`, `dependabot.yml`.
- Root — `commitlint.config.js`, `lefthook.yml`, `.markdownlint-cli2.yaml`,
  `CITATION.cff`, `SECURITY.md`; expand `CONTRIBUTING.md`;
  `scripts/check-sanitization.sh`.
- `.gitignore` — add `docs/codebase-atlas.html` (excluded per §15).
- `README.md` — apply the 3 accuracy fixes (tool count 18→24, remove phantom
  `scripts/monitor-team.sh`, refresh the Status table).
- Move the whitepaper markdown (`whitepaper-dgm-telemetry.md`) from
  `.claude-tmp/` into `docs/` for Pages — **markdown only, not the PDF**
  (whitepaper audited **CLEAN**).
- `.claude-tmp/PUBLICATION-PLAN.md` — the single-commit publication plan.
- Verified facts: 31 schema files (`base/1, goals/5, telemetry/1, tools/24`);
  whitepaper audit CLEAN; `codebase-atlas.html` excluded.
