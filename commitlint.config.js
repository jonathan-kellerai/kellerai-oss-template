// Commit message linting — Conventional Commits.
// Enforced as a hard gate by .github/workflows/commitlint.yml and the
// lefthook commit-msg hook.
//
// Aligned with the upstream /git-workflow-tools:gm-* slash commands:
// the slash command's universal hand-check enforces only format +
// type-enum + header-length. Repo-specific rules (subject-case,
// body-min-length, scope-enum, references-empty) live here as the
// single source of truth, so a message that passes the slash command
// cannot be rejected by the repo (and vice versa).
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // body-empty + body-min-length together enforce "a body must be
    // present AND at least 20 characters". body-empty alone rejects
    // missing bodies; body-min-length checks length when a body exists.
    // Both fire at severity 2 (error). MINOR: prefix commits are exempt
    // because they bypass the body check entirely via config-conventional.
    'body-empty': [2, 'never'],
    'body-min-length': [2, 'always', 20],
    'body-leading-blank': [2, 'always'],
    // subject-case: deliberately NOT overridden. config-conventional's
    // default disallows sentence-case, start-case, pascal-case, and
    // upper-case subjects — lowercase / camel-case / kebab-case / snake-case
    // are permitted. Authors needing an acronym in the subject (e.g. "OPA"
    // or "SHA") must rephrase ("opa policy", "sha pin") or use the body.
  },
};
