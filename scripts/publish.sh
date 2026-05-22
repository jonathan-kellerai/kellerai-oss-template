#!/usr/bin/env bash
# publish.sh — publication helper for kellerai-conformant repositories.
#
# Runs a pre-flight conformance gate, then (with --confirm) creates the GitHub
# repo, optionally flips visibility to public, and tags v0.1.0.
#
# SAFE BY DEFAULT: --dry-run is ON unless --confirm is passed.  Every mutating
# command is printed before execution.  Force-push is never used.
#
# Usage:
#   publish.sh --repo OWNER/NAME --description TEXT [OPTIONS]
#
# Options:
#   --repo          OWNER/NAME  GitHub repository slug (required)
#   --description   TEXT        Repository description for GitHub (required)
#   --visibility    public|private
#                               Target visibility; default: private
#   --root          PATH        Repository root; default: current directory
#   --dry-run                   Print commands only, execute nothing (default)
#   --confirm                   Actually run mutating gh/git commands
#
# Requires: git, gh (GitHub CLI), jq, opa
#
# The conformance gate calls scan-repo-structure.sh (sibling script) and
# evaluates data.kellerai.oss.conformance via `opa eval`.  Error-severity
# violations abort the run even in --dry-run mode.
set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
repo=""
description=""
visibility="private"
root=""
confirm=0       # 0 = dry-run (safe default); 1 = execute mutating commands

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
    cat <<'USAGE'
usage: publish.sh --repo OWNER/NAME --description TEXT [OPTIONS]

Required:
  --repo          OWNER/NAME   GitHub repository slug
  --description   TEXT         Repository description for GitHub

Options:
  --visibility    public|private  Target visibility after creation (default: private)
  --root          PATH            Repository root (default: cwd)
  --confirm                       Actually run mutating commands
                                  (omit for dry-run — the safe default)
  -h, --help                      Show this help and exit

Environment:
  GH_TOKEN / GITHUB_TOKEN must be set (or gh must be authenticated via
  'gh auth login') for --confirm to succeed.

Conformance pre-flight:
  Requires opa (OPA CLI) on PATH and the sibling scan-repo-structure.sh.
  Error-severity violations abort publication regardless of --confirm.
USAGE
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [ "$#" -gt 0 ]; do
    case "${1:-}" in
    --repo)        repo="${2:-}";        shift 2 ;;
    --description) description="${2:-}"; shift 2 ;;
    --visibility)  visibility="${2:-}";  shift 2 ;;
    --root)        root="${2:-}";        shift 2 ;;
    --confirm)     confirm=1;            shift   ;;
    --dry-run)
        # Accepted explicitly for clarity; it is already the default.
        confirm=0; shift ;;
    -h | --help) usage; exit 0 ;;
    *) echo "publish: unknown argument: ${1:-}" >&2; usage; exit 2 ;;
    esac
done

# ---------------------------------------------------------------------------
# Validate required flags
# ---------------------------------------------------------------------------
err=0
[ -n "$repo" ] || { echo "publish: --repo is required" >&2; err=1; }
[ -n "$description" ] || { echo "publish: --description is required" >&2; err=1; }
case "$visibility" in
public | private) ;;
*) echo "publish: --visibility must be 'public' or 'private'" >&2; err=1 ;;
esac
[ "$err" -eq 0 ] || { usage; exit 2; }

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------
script_dir="$(cd "$(dirname "$0")" && pwd)"
[ -n "$root" ] || root="$(pwd)"
root="$(cd "$root" && pwd)"

scan_script="$script_dir/scan-repo-structure.sh"
[ -f "$scan_script" ] || {
    echo "publish: scan-repo-structure.sh not found at $scan_script" >&2
    exit 1
}

# The conformance data.json and policy live in the template repo's conformance/
# directory, co-located with this script's parent.
template_root="$(cd "$script_dir/.." && pwd)"
conformance_dir="$template_root/conformance"
[ -f "$conformance_dir/conformance.rego" ] || {
    echo "publish: conformance/conformance.rego not found at $conformance_dir" >&2
    exit 1
}
[ -f "$conformance_dir/data.json" ] || {
    echo "publish: conformance/data.json not found at $conformance_dir" >&2
    exit 1
}

# ---------------------------------------------------------------------------
# Dry-run mode banner
# ---------------------------------------------------------------------------
if [ "$confirm" -eq 0 ]; then
    echo "=== DRY-RUN MODE (pass --confirm to execute mutating commands) ==="
    echo
fi

# ---------------------------------------------------------------------------
# Helper: run_cmd
#   Prints the command, then either executes it (--confirm) or skips it
#   (dry-run).  Never used for read-only pre-flight steps.
# ---------------------------------------------------------------------------
run_cmd() {
    echo "  + $*"
    if [ "$confirm" -eq 1 ]; then
        "$@"
    fi
}

echo "publish: target repo  : $repo"
echo "publish: description  : $description"
echo "publish: visibility   : $visibility"
echo "publish: root         : $root"
echo

# ===========================================================================
# PRE-FLIGHT GATE — always runs, even in dry-run mode
# ===========================================================================
echo "--- pre-flight ---"

# 1. Must be inside a git repository.
cd "$root"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "publish: ABORT — $root is not a git repository" >&2
    exit 1
}

# 2. Working tree must be clean (no unstaged changes, no untracked files).
status_out="$(git status --porcelain 2>&1)"
if [ -n "$status_out" ]; then
    echo "publish: ABORT — working tree is not clean:" >&2
    echo "$status_out" >&2
    exit 1
fi
echo "  [ok] working tree is clean"

# 3. Must be on branch 'main'.
current_branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
if [ "$current_branch" != "main" ]; then
    echo "publish: ABORT — current branch is '$current_branch'; publication requires branch 'main'" >&2
    exit 1
fi
echo "  [ok] on branch main"

# 4. 'master' branch must not exist (locally or as a remote tracking ref).
if git show-ref --verify --quiet refs/heads/master 2>/dev/null || \
   git show-ref --verify --quiet refs/remotes/origin/master 2>/dev/null; then
    echo "publish: ABORT — a 'master' branch exists; the default branch must be 'main'" >&2
    exit 1
fi
echo "  [ok] no 'master' branch"

# 5. History: exactly one commit OR a clean linear history (no open merge
#    commits).  We enforce: no uncommitted merge state (MERGE_HEAD absent).
if [ -f "$(git rev-parse --git-dir)/MERGE_HEAD" ]; then
    echo "publish: ABORT — repository is in the middle of a merge" >&2
    exit 1
fi
commit_count="$(git rev-list --count HEAD 2>/dev/null || echo 0)"
echo "  [ok] commit history: $commit_count commit(s), no in-progress merge"

# 6. Conformance check — scan the repo and evaluate with OPA.
echo
echo "  running conformance scan..."

# Check required tools for conformance.
for tool in jq opa; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "publish: ABORT — '$tool' is required for the conformance gate but was not found on PATH" >&2
        exit 1
    }
done

snapshot="$(mktemp)"
trap 'rm -f "$snapshot"' EXIT

"$scan_script" --root "$root" >"$snapshot"

# Evaluate errors only (error-severity violations block publication).
# `opa eval` exits 0 whether or not rules fire; we inspect the JSON result.
opa_result="$(
    opa eval \
        --data "$conformance_dir/data.json" \
        --data "$conformance_dir/conformance.rego" \
        --input "$snapshot" \
        --format pretty \
        'data.kellerai.oss.conformance.summary' 2>&1
)" || {
    echo "publish: ABORT — opa eval failed:" >&2
    echo "$opa_result" >&2
    exit 1
}

# Extract the summary object from OPA's pretty output.
# `opa eval --format pretty` wraps the result in {"result":[{"expressions":[...]}]}.
# Re-run with raw bindings to get clean JSON.
summary_json="$(
    opa eval \
        --data "$conformance_dir/data.json" \
        --data "$conformance_dir/conformance.rego" \
        --input "$snapshot" \
        --format raw \
        'data.kellerai.oss.conformance.summary'
)"

allow="$(printf '%s' "$summary_json" | jq -r '.allow // false')"
error_count="$(printf '%s' "$summary_json" | jq -r '.errors // 0')"
warning_count="$(printf '%s' "$summary_json" | jq -r '.warnings // 0')"

echo "  conformance result: allow=$allow  errors=$error_count  warnings=$warning_count"

if [ "$allow" != "true" ]; then
    echo
    echo "  error-severity violations:"
    # Re-run to surface individual error entries for the user.
    opa eval \
        --data "$conformance_dir/data.json" \
        --data "$conformance_dir/conformance.rego" \
        --input "$snapshot" \
        --format raw \
        '[x | x := data.kellerai.oss.conformance.errors[_]; x]' |
        jq -r '.[] | "    [error] \(.rule): \(.msg)"' >&2 || true
    echo
    echo "publish: ABORT — $error_count error-severity conformance violation(s) must be resolved before publication" >&2
    exit 1
fi

if [ "$warning_count" -gt 0 ]; then
    echo "  (non-blocking) warnings:"
    opa eval \
        --data "$conformance_dir/data.json" \
        --data "$conformance_dir/conformance.rego" \
        --input "$snapshot" \
        --format raw \
        '[x | x := data.kellerai.oss.conformance.warnings[_]; x]' |
        jq -r '.[] | "    [warn]  \(.rule): \(.msg)"' || true
fi

echo "  [ok] conformance gate passed"
echo

# ===========================================================================
# PUBLICATION COMMANDS
# ===========================================================================
echo "--- publication steps ---"
echo

# Step 1: Create the GitHub repository (private by default; --visibility flag
#         sets the final state, but we always create private first to allow
#         review before the repo becomes public).
echo "Step 1: create GitHub repository (private)"
run_cmd gh repo create "$repo" \
    --private \
    --source="$root" \
    --remote=origin \
    --push \
    --description "$description"
echo

# Step 2: If the requested visibility is 'public', flip it now.
if [ "$visibility" = "public" ]; then
    echo "Step 2: set repository visibility to public"
    run_cmd gh repo edit "$repo" --visibility public
else
    echo "Step 2: skipped — visibility is already 'private' (requested)"
fi
echo

# Step 3: Tag v0.1.0 and push the tag.
echo "Step 3: tag v0.1.0 and push"
run_cmd git -C "$root" tag -a v0.1.0 -m "Initial public release"
run_cmd git -C "$root" push origin v0.1.0
echo

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
if [ "$confirm" -eq 1 ]; then
    echo "publish: done."
    echo "  repo   : https://github.com/$repo"
    echo "  tag    : v0.1.0"
    echo "  visibility: $visibility"
else
    echo "=== DRY-RUN complete — no commands were executed."
    echo "    Re-run with --confirm to publish."
fi
