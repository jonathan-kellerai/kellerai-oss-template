# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `scripts/bootstrap_test.sh` — a regression test that bootstraps every artifact
  type and asserts a clean leftover-token scan, `opa check`/`opa test`, and a
  passing conformance self-check.
- Golden-repo gates carried into every bootstrapped repo via `template/_files/`:
  an `agentic-gates` job in `.github/workflows/conformance.yml`,
  `scripts/preflight.sh`, `docs/adr/ADR-000-template.md`,
  `docs/claude-settings.template.json`, and a "Capability Roster" section in
  `AGENTS.md`. All are TIER-2/TIER-3 — no new conformance-required file is added.

### Changed

- `scripts/bootstrap.sh` is hardened against incident classes IC-1..IC-7: a
  dependency preflight, fail-fast validation of every flag, atomic generation in
  a temp staging tree (a failure never leaves a partial tree at `--out`), a
  `--force` no-clobber guard, a leftover-token scan, and a post-generation OPA
  conformance self-check. Generated repos are now golden-conformant by
  construction.

### Fixed

- `scripts/bootstrap.sh`: skip non-text files (e.g. `.DS_Store`) during token
  substitution. The sed loop previously errored with `RE error: illegal byte
  sequence` if the template tree picked up local macOS Finder cruft; CI is
  unaffected (fresh checkout has no cruft), but local runs of
  `bootstrap_test.sh` could fail. The loop now uses `grep -Iq .` to skip
  binary or empty files before invoking sed.

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
