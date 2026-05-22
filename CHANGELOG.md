# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-05-22

### Added

- Four-tier branch governance model (external → dev → qa → main) with three gate workflows:
  `validate-branch-name`, `validate-branch-tier`, and `validate-linked-issue` under
  `.github/workflows/`; templated copies under `template/_files/.github/workflows/` for
  bootstrapped repos; and `docs/branch-governance.md` documenting the model.

### Changed

- **BREAKING:** the three branch-governance workflows are now listed in `required_github_files`
  in `conformance/data.json` — every conformant kellerai repo must provide them. Consumers pin
  a SHA, so this takes effect on each consumer's next pin bump.

### Fixed

- CI: pinned `markdownlint-cli2` to an exact version in `.github/workflows/ci.yml` (was floating
  `npx --yes`, which silently broke when a new markdownlint release added rule MD060).
- CI: disabled MD060 (cosmetic table-column-style) and MD041 (conflicts with the mandated
  `@AGENTS.md` first line of `CLAUDE.md`) in `.markdownlint-cli2.yaml`; fixed 15 genuine
  markdown errors (missing code-fence languages, bare URLs, list spacing) across `docs/` and
  `README.md`.
- CI: fixed a silent-failure in the reusable conformance workflow
  (`.github/workflows/conformance.yml`) — the policy-evaluation step discarded `opa eval`
  stderr and ignored its exit code, so a failed evaluation reported only
  `(no output from opa eval)`. It now captures stderr, checks the exit code, surfaces the real
  error, and uses `--format json`.
