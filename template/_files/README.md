# {{REPO_NAME}}

{{DESCRIPTION}}

---

## What this repository is

- A **{{ARTIFACT_TYPE}}** artifact maintained under Apache-compatible open source.
- The load-bearing artifact lives in [`{{ARTIFACT_DIR}}/`]({{ARTIFACT_DIR}}/).
- Licensed **{{LICENSE_ID}}** — see [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).

## What this repository is NOT

- There is no runtime implementation here.
  The artifact defines a contract; consumers implement against it.
- There is no build system to invoke.
  The only verification commands are those for `{{PRIMARY_VALIDATOR}}`.

## Repository layout

| Path | What it contains |
|------|-----------------|
| [`{{ARTIFACT_DIR}}/`]({{ARTIFACT_DIR}}/) | The primary artifact |
| [`docs/`](docs/) | Design docs and Tier-2 agent guides |
| [`scripts/`](scripts/) | Validation and sanitization helpers |
| [`.github/`](.github/) | Workflows, issue templates, CODEOWNERS |

## Status

`v0.1.0` — initial public release.

## License

Licensed under the **{{LICENSE_ID}} License**.
Full text in [`LICENSE`](LICENSE); attribution in [`NOTICE`](NOTICE).

---

### For agents

Agents reading this repository should start at [AGENTS.md](AGENTS.md), not this README.
Claude Code users: see [CLAUDE.md](CLAUDE.md), which imports `AGENTS.md`.
The agent files document the conventions, vocabulary, and contribution discipline that agents are expected to follow.
