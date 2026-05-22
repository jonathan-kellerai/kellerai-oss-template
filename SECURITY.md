# Security Policy

`kellerai-oss-template` is a conformance policy and bootstrap scaffold, not a running system.
A security-relevant defect here is a rule or template that — when applied faithfully —
would create a vulnerability in a consuming repository.

Examples of in-scope defects:

- A conformance rule that could be bypassed by a trivially crafted `repo-structure.json` input,
  allowing a structurally non-conformant repo to pass CI.
- A template file in `template/_files/` that emits an insecure default (for example,
  a workflow that runs on `pull_request_target` without the cautions that event requires,
  or a `CODEOWNERS` pattern that inadvertently leaves sensitive paths unprotected).
- A `check-sanitization.sh` logic flaw that allows a matching internal term to pass undetected.
- A `bootstrap.sh` flaw that generates a `.kellerai-oss.json` marker with an incorrect artifact
  type, causing the policy to silently skip artifact-type-specific checks.
- A `scan-repo-structure.sh` flaw in branch enumeration or `file_meta` capture that causes the
  policy to miss a required check.

## Reporting a vulnerability

Report suspected security-relevant defects **privately**, through GitHub's **Security Advisories** —
use the *Report a vulnerability* button on this repository's **Security** tab.
Do not open a public issue for these.

Include:

- The affected file and line range (e.g. `conformance/conformance.rego:243-254`,
  `scripts/bootstrap.sh:84-97`).
- A description of the defect and the failure it would produce in a consuming repo.
- If applicable, a minimal `repo-structure.json` input or a bootstrap invocation that
  demonstrates the bypass.

You can expect an initial response within a reasonable time.
If a defect is confirmed, it is corrected, the policy integrity digest is refrozen,
and the fix is recorded in `CHANGELOG.md`.

## Scope

This policy covers the `kellerai-oss-template` repository only — the conformance policy,
scripts, and templates in this repo.
It does not cover downstream repositories that consume the reusable workflow or the
bootstrap output. The security of a consumer repo is the responsibility of its own maintainers.

## Supported versions

Only the current published version (`v0.1.0` and later tags on `main`) is in scope.
There is no back-port channel.
