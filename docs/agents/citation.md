# Citing kellerai-oss-template

Tier-2 detail for `AGENTS.md`. How to cite this repository when you reference
it in a paper, codebase, or downstream tool.

## Licence

The repository is licensed **Apache-2.0** (see `LICENSE` and `NOTICE`). You
may use, share, and adapt the material — including commercially — under the
terms of that licence. Attribution is required; see the templates below.

## Plain-text attribution

> *kellerai-oss-template* — OPA/Rego OSS structural conformance policy and
> bootstrap scaffold (version 0.1.0). Jonathan A. Bowe, 2026.
> Licensed Apache-2.0. https://github.com/jonathan-kellerai/kellerai-oss-template

When citing a specific rule or behaviour, add the file and line:
`conformance/conformance.rego:119` for the `artifact_type_known` rule.

## BibTeX

```bibtex
@misc{kellerai-oss-template2026,
  author       = {Bowe, Jonathan A.},
  title        = {{kellerai-oss-template: OPA/Rego OSS structural conformance
                   policy and bootstrap scaffold}},
  year         = {2026},
  version      = {0.1.0},
  howpublished = {\url{https://github.com/jonathan-kellerai/kellerai-oss-template}},
  note         = {Licensed Apache-2.0}
}
```

Pin the version. The schema and policy interfaces may change before `1.0.0`.

## Citation slug

`kellerai-oss-template 0.1.0` — always include the version number.

## Machine-readable citation

The repository ships `CITATION.cff` at its root (Citation File Format 1.2.0).
GitHub's "Cite this repository" widget and Zenodo archiving both read it
automatically. The `CITATION.cff` is the authoritative citation source; the
templates above restate it for convenience.

Verify `CITATION.cff` against https://citation-file-format.github.io/ before
modifying it — do not invent fields from memory.

## Citing the OPA/Rego policy specifically

If you are citing the conformance policy (not the repo as a whole), use:

> kellerai-oss-template `conformance/conformance.rego` (package
> `kellerai.oss.conformance`), version 0.1.0.
> https://github.com/jonathan-kellerai/kellerai-oss-template

Reference specific rules by rule id and line range — e.g.
`conformance.rego:243-254` for the `policy_integrity` rule.

## Citing the OSS publication standard

The prose standard that the policy machine-enforces is tracked in
`standard/OSS-PUBLICATION-STANDARD.md`. Cite it as:

> *kellerai OSS Publication Standard* (2026-05-21). Jonathan A. Bowe.
> Distributed with kellerai-oss-template v0.1.0.
> https://github.com/jonathan-kellerai/kellerai-oss-template
