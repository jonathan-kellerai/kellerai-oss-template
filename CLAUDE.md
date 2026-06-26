@AGENTS.md

## Claude-specific notes

The import above pulls `AGENTS.md` into context — everything in that file applies.
The notes below are specific to Claude Code sessions.

- **No application runtime.** Do not run `cargo`, `npm install`, `python -m`, `pytest`,
  `make`, or any build/test command — there is no implementation. The only verification
  commands are:

  ```bash
  opa check conformance/                   # syntax + type check
  opa test conformance/                    # run the test suite (recurses into conformance/laas/)
  opa eval -d conformance/ -i repo-structure.json \
    'data.kellerai.oss.conformance.summary'  # evaluate a snapshot
  ```

  Generate the snapshot first with `bash scripts/scan-repo-structure.sh > repo-structure.json`
  (the script writes the JSON to stdout; redirect it to the file `opa eval -i` reads).

- **Policy integrity.** After editing `conformance/conformance.rego`, recompute the
  SHA-256 digest and update `conformance/data.json` `policy_integrity.expected_digest`
  before committing:

  ```bash
  sha256sum conformance/conformance.rego   # macOS: shasum -a 256
  ```

- **No in-repo issue tracker.** There is no `.beads/` directory. Do not invoke `bd`,
  `bv`, or any tracker tooling. Work is tracked in GitHub Issues once the repo is public.

- **Staging boundary.** `.gitignore` is the source of truth for what ships. Files matched
  by `.gitignore` are staging-only and must never be published. The `.claude-tmp/`
  directory is staging-only by that rule.

- **Frozen content.** `conformance/**`, `scripts/**`, and `template/**` passed an
  adversarial review. Change them only with explicit maintainer approval and a
  semver-classified `CHANGELOG.md` entry.

- **Citations.** Internal references use `file:line`. Never assert a policy or schema
  fact without pointing at the file that proves it.

- **Prose edits.** Use the `writing-clearly-and-concisely` skill for human-facing prose.
  Use `human-writing` for tone passes when those skills are available.
