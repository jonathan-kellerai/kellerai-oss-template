# docs/ — kellerai-oss-template

This directory is the documentation root for `kellerai-oss-template` —
the OPA/Rego structural-conformance policy, tokenized bootstrap templates,
and reusable conformance workflow for the kellerai OSS family.

---

## In this directory

| File | Audience | What it covers |
|------|----------|----------------|
| [`conformance-policy.md`](conformance-policy.md) | All | Complete catalog of every rule in `conformance/conformance.rego`: rule id, severity, trigger, fix. Also documents the four artifact types, the surface rules, and the `data.json` manifest structure. |
| [`adoption-guide.md`](adoption-guide.md) | Sibling repo maintainers | Step-by-step: add `.kellerai-oss.json`, wire the reusable `conformance` job into CI, run the check locally. |

## Agent Tier-2 references — `docs/agents/`

Load on demand; `AGENTS.md` summarises each.

| File | What it covers |
|------|----------------|
| [`agents/conventions.md`](agents/conventions.md) | Conventional Commits spec, branch naming (including agent edge cases), PR style, citation format, `opa`/`ajv` validation workflow. |
| [`agents/citation.md`](agents/citation.md) | Apache-2.0 attribution, BibTeX template, CITATION.cff usage. |
| [`agents/glossary.md`](agents/glossary.md) | Load-bearing vocabulary: conformance, structural drift, artifact type, reusable workflow, SSOT, bootstrap, tokenized template, sentinel guard, deny set, severity, policy integrity digest. |
| [`agents/enforcement.md`](agents/enforcement.md) | How conformance is enforced going forward: CI gate, error vs warning severity, the policy self-integrity digest, CODEOWNERS lock, pre-commit hook. |

---

## Quick orientation

- The machine-checkable policy lives in `conformance/` (`conformance.rego` +
  `data.json`). Start there if you are modifying rules.
- The bootstrap scaffold lives in `template/` and is applied by
  `scripts/bootstrap.sh`.
- The reusable GitHub Actions workflow lives in
  `.github/workflows/conformance.yml`. Sibling repos call it via `uses:`.
- `conformance/README.md` explains how to run `opa eval` locally.
