## Summary

<!-- What does this PR change, and why? -->

## Artifacts touched

<!--
Which files changed? Group by area:
  - standard/  (OSS-PUBLICATION-STANDARD.md)
  - conformance/  (conformance.rego, data.json, conformance_test.rego)
  - template/  (scaffold files, licenses, manifests)
  - scripts/  (scan-repo-structure.sh, bootstrap.sh, check-sanitization.sh)
  - docs/  (adoption guide, policy docs, agent docs)
  - .github/  (workflows, templates, CODEOWNERS, dependabot)
-->

## Validation output

<!--
Paste the output of the relevant checks you ran locally:

  opa check conformance/
  opa test conformance/ --verbose
  bash scripts/check-sanitization.sh
  bash scripts/scan-repo-structure.sh --artifact-type rego-policy > /tmp/rs.json \
    && opa eval -d conformance/ -i /tmp/rs.json 'data.kellerai.oss.conformance.summary'
-->

## Semver classification

<!-- Mark exactly one. See CHANGELOG.md for the semver policy. -->

- [ ] **major** — removes or renames a required file/rule, or adds an error-severity check that existing conformant repos would fail
- [ ] **minor** — additive, backward-compatible (new optional field, new warning check, new artifact type)
- [ ] **patch** — clarification, editorial, or docs-only; no policy behaviour change

## Contributor

- [ ] I am an agent acting on behalf of `<handle>`
