# Branch Governance — kellerai-oss-template

Tier-2 detail for `AGENTS.md`.
Authoritative source for the 4-tier branch model, external contributor naming,
gate workflow configuration, and GitHub Rulesets setup.
When this model changes, update this file first, then propagate to `AGENTS.md`
and `docs/agents/conventions.md`.

## Overview

Kellerai OSS repositories use a 4-tier promotion model.
External contributions land in `dev`, are smoke-tested in `qa`, and are
squash-merged to `main` only after CODEOWNER review.

```text
external/<type>-<KEY>-<scope>-<gerund>-p<N>
        |
        |  PR + validate-branch-name
        |  validate-linked-issue
        v
       dev
        |
        |  PR + validate-branch-tier
        v
        qa
        |
        |  PR + validate-branch-tier
        |  squash-only
        |  CODEOWNER review
        v
       main
```

Each arrow represents one pull request.
No branch may be pushed to directly — every tier is protected by a GitHub Ruleset
(see [GitHub Rulesets configuration](#github-rulesets-configuration)).

## Branch naming convention

Internal maintainers (listed in `.github/CODEOWNERS`) follow the convention
defined in `docs/agents/conventions.md`:

```text
<type>/<ISSUE-KEY>-<scope>-<gerund>
```

Example: `feat/ABC-123-auth-adding-oauth`

External contributors use a mandatory `external/` prefix:

```text
external/<type>-<ISSUE-KEY>-<scope>-<gerund>-p<N>
```

Example: `external/feat-ABC-123-auth-adding-oauth-p1`

The prefix is machine-checkable and routes the branch through the three gate
workflows automatically.

### Token definitions

| Token | Meaning | Constraints |
|-------|---------|-------------|
| `<type>` | Change category | One of: `feat fix chore docs refactor test ci build perf revert style hotfix spike wip release rnd` |
| `<ISSUE-KEY>` | Tracker key | Linear key (`ABC-123`) or GitHub issue number (`123`) |
| `<scope>` | Affected area | kebab-case; examples: `auth`, `schemas-base`, `conformance` |
| `<gerund>` | Action phrase | Present-participle, hyphen-separated; examples: `adding-oauth`, `fixing-null` |
| `<N>` | Priority digit | `0`=critical `1`=high `2`=medium `3`=low `4`=backlog |

### RE2 regex

Used by the `restrict-external-naming` GitHub Ruleset and `validate-branch-name.yml`:

```text
^external/(?:feat|fix|chore|docs|refactor|test|ci|build|perf|revert|style|hotfix|spike|wip|release|rnd)-[A-Z]+-\d+(?:-[a-z][a-z0-9]*)+-p[0-4]$
```

## Gate workflows

Three required-status-check workflows enforce the model.
All three must be registered as required checks on the target branch
(see [GitHub Rulesets configuration](#github-rulesets-configuration)).

### `validate-branch-name.yml`

- **Fires on:** PRs targeting `dev` where the source branch matches `external/**`.
- **What it does:** Runs a Python `re.search()` against the branch name using the
  RE2 regex above. Fails if the name does not match.
- **Check context string:** `Branch name pattern (external/)`

### `validate-branch-tier.yml`

- **Fires on:** PRs targeting `dev`, `qa`, or `main`.
- **What it does:** Reads `.github/CODEOWNERS` to determine whether the PR author
  is an internal maintainer. Enforces that:
  - `external/` branches may only target `dev`.
  - `dev` may only promote to `qa`.
  - `qa` may only promote to `main`.
- **Check context strings:**
  `Branch tier (dev <- *)`, `Branch tier (qa <- *)`, `Branch tier (main <- *)`

### `validate-linked-issue.yml`

- **Fires on:** PRs targeting `dev`.
- **What it does:** Extracts the issue key from the branch name (segment matching
  `[A-Z]+-\d+` or a bare integer). Verifies the issue is Open and carries the
  `codeowner-approved` label via the GitHub Issues API. When `LINEAR_API_KEY` is
  set, defers to the Linear API instead (see [Linear integration](#linear-integration)).
- **Check context string:** `Linked issue open + codeowner-approved`

## GitHub Rulesets configuration

Run the four commands below once per repository.
Replace `{owner}/{repo}` with the actual slug — for this repo that is
`jonathan-kellerai/kellerai-oss-template`.
The `-F 'rules=[...]'` flag passes the value as raw JSON.

### Ruleset 1 — protect-main

```bash
gh api repos/{owner}/{repo}/rulesets \
  --method POST \
  --header "Accept: application/vnd.github+json" \
  -f name="protect-main" \
  -f target="branch" \
  -f enforcement="active" \
  -F 'conditions={"ref_name":{"include":["refs/heads/main"],"exclude":[]}}' \
  -F 'rules=[
    {"type":"deletion"},
    {"type":"non_fast_forward"},
    {"type":"required_linear_history"},
    {"type":"pull_request","parameters":{
      "allowed_merge_methods":["squash"],
      "dismiss_stale_reviews_on_push":true,
      "require_code_owner_review":true,
      "require_last_push_approval":true,
      "required_approving_review_count":1,
      "required_review_thread_resolution":true
    }},
    {"type":"required_status_checks","parameters":{
      "strict_required_status_checks_policy":false,
      "required_status_checks":[
        {"context":"Branch name pattern (external/)"},
        {"context":"Branch tier (main <- *)"},
        {"context":"Linked issue open + codeowner-approved"},
        {"context":"AJV schema compile + example validation"},
        {"context":"Conformance (kellerai OSS standard)"}
      ]
    }}
  ]'
```

### Ruleset 2 — protect-qa

```bash
gh api repos/{owner}/{repo}/rulesets \
  --method POST \
  --header "Accept: application/vnd.github+json" \
  -f name="protect-qa" \
  -f target="branch" \
  -f enforcement="active" \
  -F 'conditions={"ref_name":{"include":["refs/heads/qa"],"exclude":[]}}' \
  -F 'rules=[
    {"type":"deletion"},
    {"type":"non_fast_forward"},
    {"type":"pull_request","parameters":{
      "allowed_merge_methods":["squash"],
      "dismiss_stale_reviews_on_push":true,
      "require_code_owner_review":true,
      "required_approving_review_count":1
    }},
    {"type":"required_status_checks","parameters":{
      "strict_required_status_checks_policy":false,
      "required_status_checks":[
        {"context":"Branch tier (qa <- *)"}
      ]
    }}
  ]'
```

### Ruleset 3 — protect-dev

```bash
gh api repos/{owner}/{repo}/rulesets \
  --method POST \
  --header "Accept: application/vnd.github+json" \
  -f name="protect-dev" \
  -f target="branch" \
  -f enforcement="active" \
  -F 'conditions={"ref_name":{"include":["refs/heads/dev"],"exclude":[]}}' \
  -F 'rules=[
    {"type":"deletion"},
    {"type":"non_fast_forward"},
    {"type":"pull_request","parameters":{
      "allowed_merge_methods":["squash"],
      "required_approving_review_count":1
    }},
    {"type":"required_status_checks","parameters":{
      "strict_required_status_checks_policy":false,
      "required_status_checks":[
        {"context":"Branch tier (dev <- *)"},
        {"context":"Branch name pattern (external/)"},
        {"context":"Linked issue open + codeowner-approved"}
      ]
    }}
  ]'
```

### Ruleset 4 — restrict-external-naming

```bash
gh api repos/{owner}/{repo}/rulesets \
  --method POST \
  --header "Accept: application/vnd.github+json" \
  -f name="restrict-external-naming" \
  -f target="branch" \
  -f enforcement="active" \
  -F 'conditions={"ref_name":{"include":["refs/heads/external/**"],"exclude":[]}}' \
  -F 'rules=[
    {"type":"branch_name_pattern","parameters":{
      "operator":"regex",
      "pattern":"^external/(?:feat|fix|chore|docs|refactor|test|ci|build|perf|revert|style|hotfix|spike|wip|release|rnd)-[A-Z]+-\\d+(?:-[a-z][a-z0-9]*)+-p[0-4]$",
      "negate":false
    }}
  ]'
```

## Linear integration

`validate-linked-issue.yml` falls back to the GitHub Issues API by default.
To enable Linear issue validation:

1. Add `LINEAR_API_KEY` as a repository secret:

   ```bash
   gh secret set LINEAR_API_KEY
   ```

2. The workflow detects Linear-style keys (segment matching `[A-Z]+-\d+`) and,
   when the secret is present, queries `https://api.linear.app/graphql` instead
   of the GitHub Issues API.
   Without the secret the workflow logs a notice and does not fail — full Linear
   API validation requires extending the workflow script to call that endpoint.

3. Set the Linear workspace branch template in Linear Settings → Preferences →
   Git branch format:

   ```text
   external/{type}-{id}-{title}-p{priority}
   ```

   Linear replaces spaces with hyphens and lowercases the title automatically,
   producing branches that satisfy the RE2 regex above.

## Contributor workflow summary

The end-to-end path from issue to `main`:

```text
1. A CODEOWNER approves the issue and applies the 'codeowner-approved' label.
2. Contributor forks or creates an external/ branch:
     external/feat-ABC-123-auth-adding-oauth-p1
3. Contributor opens PR from external/<branch> -> dev.
4. Three gate checks run automatically:
     - validate-branch-name  (name matches RE2 pattern)
     - validate-linked-issue  (issue is Open + codeowner-approved)
     - validate-branch-tier   (external/ may only target dev)
5. CODEOWNER reviews and squash-merges to dev.
6. Maintainer opens PR from dev -> qa (validate-branch-tier passes).
7. After QA passes, maintainer opens PR from qa -> main
     (squash-only, CODEOWNER review required, validate-branch-tier passes).
```

No commits reach `main` without traversing all three tiers.
The CODEOWNERS lock described in `docs/agents/enforcement.md` applies at every
merge into `main`.
