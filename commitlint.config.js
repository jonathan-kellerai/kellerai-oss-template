// Commit message linting — Conventional Commits.
// Enforced as a hard gate by .github/workflows/commitlint.yml.
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'subject-case': [0], // disabled — agents author headers with proper-cased terms/acronyms
  },
};
