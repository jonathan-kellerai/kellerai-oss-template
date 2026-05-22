# Citing {{REPO_NAME}}

Tier-2 detail for [`../../AGENTS.md`](../../AGENTS.md).
This document covers how to cite **{{REPO_NAME}}** when you reference it elsewhere.

## License

The repository is licensed **{{LICENSE_ID}}**
(see [`../../LICENSE`](../../LICENSE) and [`../../NOTICE`](../../NOTICE)).
You may use, share, and adapt the material under the terms of the license.

## Attribution template

> *{{REPO_NAME}}* (version 0.1.0).
> {{AUTHOR}}, {{YEAR}}. Licensed {{LICENSE_ID}}.
> https://github.com/{{REPO_SLUG}}

When you cite a specific claim, add the file and line —
e.g. `{{ARTIFACT_DIR}}/example.json:42` for a specific field definition.

## BibTeX

```bibtex
@misc{{{REPO_NAME}}{{YEAR}},
  author       = {Bowe, Jonathan A.},
  title        = {{{REPO_NAME}}},
  year         = {{{YEAR}}},
  version      = {0.1.0},
  howpublished = {\url{https://github.com/{{REPO_SLUG}}}},
  note         = {{{ARTIFACT_TYPE}} artifact. Licensed {{LICENSE_ID}}}
}
```

## Suggested citation slug

`{{REPO_NAME}} 0.1.0` — always pin the version.

## Machine-readable citation

The repository ships a [`CITATION.cff`](../../CITATION.cff) file at its root,
so GitHub's "Cite this repository" widget and Zenodo archiving work automatically.
It is the authoritative citation source; the templates above restate it for convenience.
