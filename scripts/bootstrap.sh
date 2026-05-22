#!/usr/bin/env bash
# bootstrap.sh — scaffold a new kellerai-conformant repository from the
# template/ scaffold. Generation only: it does not git-init, commit, or push.
#
# Hardened against the golden-repo incident ledger
# (artifacts/golden-repo-triage/01-incident-ledger.md, IC-1..IC-7): fail-fast
# input validation, atomic generation in a temp staging tree, a no-clobber
# guard, a leftover-token scan, and a post-generation conformance self-check.
# A failure never leaves a partial tree at --out.
set -euo pipefail

# --- H8 error discipline — IC-5 (fail fast; never silently fail or loop) ------
# One staging dir; the EXIT trap removes it on every exit path. Every failure
# path prints a one-line remediation to stderr via die() and exits non-zero.
_staging=""
cleanup() {
	if [ -n "$_staging" ] && [ -d "$_staging" ]; then
		rm -rf "$_staging"
	fi
}
trap cleanup EXIT

die() {
	printf 'bootstrap: %s\n' "$1" >&2
	exit "${2:-2}"
}

name=""
atype=""
license=""
noun=""
validator=""
out=""
artifact_dir=""
owner="jonathan-kellerai"
author="Jonathan A. Bowe"
description=""
force=0

usage() {
	cat <<'USAGE'
usage: bootstrap.sh --name NAME --artifact-type TYPE --license LICENSE \
                    --noun NOUN --out DIR [--validator V] [--artifact-dir D] \
                    [--owner OWNER] [--author AUTHOR] [--description TEXT] \
                    [--force]

  --artifact-type   one of: json-schema markdown-spec rego-policy rag-config
  --license         one of: Apache-2.0 CC-BY-4.0 MIT
  --force           overwrite a non-empty --out directory
USAGE
}

while [ "$#" -gt 0 ]; do
	case "${1:-}" in
	--name) name="${2:-}"; shift 2 ;;
	--artifact-type) atype="${2:-}"; shift 2 ;;
	--artifact-dir) artifact_dir="${2:-}"; shift 2 ;;
	--license) license="${2:-}"; shift 2 ;;
	--noun) noun="${2:-}"; shift 2 ;;
	--validator) validator="${2:-}"; shift 2 ;;
	--out) out="${2:-}"; shift 2 ;;
	--owner) owner="${2:-}"; shift 2 ;;
	--author) author="${2:-}"; shift 2 ;;
	--description) description="${2:-}"; shift 2 ;;
	--force) force=1; shift ;;
	-h | --help) usage; exit 0 ;;
	*) usage >&2; die "unknown argument: ${1:-}" ;;
	esac
done

script_dir="$(cd "$(dirname "$0")" && pwd)"
template_root="$(cd "$script_dir/.." && pwd)"
files_src="$template_root/template/_files"
licenses_src="$template_root/template/licenses"
scan_script="$script_dir/scan-repo-structure.sh"
policy_dir="$template_root/conformance"

# --- H7 preflight — IC-1 (verify every dependency before any work begins) ----
for tool in bash git opa jq sed grep find mktemp date; do
	command -v "$tool" >/dev/null 2>&1 ||
		die "required tool not found on PATH: $tool (install it and re-run)"
done
[ -d "$files_src" ] ||
	die "template files not found at $files_src (run from a kellerai-oss-template checkout)"
[ -f "$scan_script" ] ||
	die "conformance scanner not found at $scan_script"
[ -d "$policy_dir" ] ||
	die "conformance policy directory not found at $policy_dir"

# --- H1 input validation — IC-7 (validate every flag before any file is written)
[ -n "$name" ] || die "--name is required"
[ -n "$out" ] || die "--out is required"
[ -n "$noun" ] || die "--noun is required"
[ -n "$license" ] || die "--license is required"

# --name is interpolated into paths and substituted via sed: require a safe slug.
case "$name" in
*[!a-z0-9._-]* | [!a-z0-9]*)
	die "--name '$name' is not a valid slug: lowercase a-z 0-9 . _ - only, starting alphanumeric" ;;
esac

# --owner feeds REPO_SLUG and is substituted via sed: require a safe slug.
case "$owner" in
"" | *[!a-zA-Z0-9-]*)
	die "--owner '$owner' is not a valid slug: a-z A-Z 0-9 - only" ;;
esac

# --author is a free-form name, but is substituted via sed (delimiter '|').
case "$author" in
"" | *'|'* | *\\*) die "--author must be non-empty and contain no '|' or backslash" ;;
esac
case "$author" in *$'\n'*) die "--author must be a single line" ;; esac

# --artifact-type must be one of the four known types.
case "$atype" in
json-schema | markdown-spec | rego-policy | rag-config) ;;
*) die "--artifact-type must be one of: json-schema markdown-spec rego-policy rag-config" ;;
esac

# --license must be a known SPDX id with a license body in template/licenses/.
case "$license" in
Apache-2.0 | CC-BY-4.0 | MIT) ;;
*) die "--license must be one of: Apache-2.0 CC-BY-4.0 MIT" ;;
esac
[ -f "$licenses_src/$license.txt" ] ||
	die "license body not found: $licenses_src/$license.txt"

# --noun is substituted into file paths: keep it a simple lowercase token.
case "$noun" in
*[!a-z0-9-]*) die "--noun '$noun' must use lowercase a-z 0-9 - only" ;;
esac

# --artifact-dir must be a repo-relative path with no traversal or sed metachars.
case "$artifact_dir" in
/* | *..* | *'|'* | *\\*)
	die "--artifact-dir '$artifact_dir' must be repo-relative with no '..', '|' or backslash" ;;
esac

# --description is substituted via sed (delimiter '|'): reject chars that break it.
case "$description" in
*'|'* | *\\*) die "--description must not contain '|' or backslash characters" ;;
esac
case "$description" in *$'\n'*) die "--description must be a single line" ;; esac

# --out parent must already exist; --out itself is created by this script.
out_parent="$(dirname "$out")"
[ -d "$out_parent" ] ||
	die "--out parent directory does not exist: $out_parent"

# --- H3 no-clobber idempotency — IC-6 (never silently overwrite --out) -------
if [ -e "$out" ] && [ -n "$(ls -A "$out" 2>/dev/null || true)" ]; then
	[ "$force" -eq 1 ] ||
		die "--out directory '$out' exists and is not empty (pass --force to overwrite)"
fi

# Resolve per-type defaults.
case "$atype" in
json-schema) default_dir="schemas"; default_validator="ajv" ;;
markdown-spec) default_dir="specs"; default_validator="markdownlint" ;;
rego-policy) default_dir="conformance"; default_validator="opa" ;;
rag-config) default_dir="configs"; default_validator="ajv" ;;
esac
[ -n "$artifact_dir" ] || artifact_dir="$default_dir"
[ -n "$validator" ] || validator="$default_validator"
year="$(date +%Y)"

# --- H2 atomic generation — IC-1, IC-6 (build in a temp tree; publish on success)
_staging="$(mktemp -d "${TMPDIR:-/tmp}/kellerai-bootstrap.XXXXXX")"
work="$_staging/repo"
mkdir -p "$work"
cp -R "$files_src/." "$work/"

# Token substitution across every generated file.
while IFS= read -r -d '' f; do
	# Skip non-text files (e.g. .DS_Store, images). sed errors out on binary
	# input ("RE error: illegal byte sequence") and tokens never appear in
	# binary content anyway. — IC-5 (fail fast on real problems; never
	# error on cruft that has no tokens).
	if ! grep -Iq . "$f" 2>/dev/null; then
		continue
	fi
	sed \
		-e "s|{{REPO_NAME}}|$name|g" \
		-e "s|{{REPO_SLUG}}|$owner/$name|g" \
		-e "s|{{OWNER}}|$owner|g" \
		-e "s|{{AUTHOR}}|$author|g" \
		-e "s|{{YEAR}}|$year|g" \
		-e "s|{{ARTIFACT_TYPE}}|$atype|g" \
		-e "s|{{ARTIFACT_DIR}}|$artifact_dir|g" \
		-e "s|{{ARTIFACT_NOUN}}|$noun|g" \
		-e "s|{{PRIMARY_VALIDATOR}}|$validator|g" \
		-e "s|{{LICENSE_ID}}|$license|g" \
		-e "s|{{DESCRIPTION}}|$description|g" \
		"$f" >"$f.tmp" || die "token substitution failed for $f"
	mv "$f.tmp" "$f"
done < <(find "$work" -type f -print0)

# Rename files whose paths still contain tokens (e.g. {{ARTIFACT_NOUN}}-bug.yml).
while IFS= read -r -d '' f; do
	newf="$(printf '%s' "$f" |
		sed -e "s|{{REPO_NAME}}|$name|g" \
			-e "s|{{ARTIFACT_TYPE}}|$atype|g" \
			-e "s|{{ARTIFACT_DIR}}|$artifact_dir|g" \
			-e "s|{{ARTIFACT_NOUN}}|$noun|g" \
			-e "s|{{PRIMARY_VALIDATOR}}|$validator|g" \
			-e "s|{{LICENSE_ID}}|$license|g")"
	if [ "$newf" != "$f" ]; then
		mkdir -p "$(dirname "$newf")"
		mv "$f" "$newf"
	fi
done < <(find "$work" -depth -type f -name '*{{*}}*' -print0)

# License body (verbatim; never tokenized).
cp "$licenses_src/$license.txt" "$work/LICENSE"

# Artifact directory + conformance marker.
mkdir -p "$work/$artifact_dir"
: >"$work/$artifact_dir/.gitkeep"

cat >"$work/.kellerai-oss.json" <<JSON
{
  "artifact_type": "$atype",
  "artifact_dir": "$artifact_dir",
  "primary_validator": "$validator",
  "owner": "$owner"
}
JSON

# --- H4 leftover-token scan — IC-2 (no unreplaced placeholder may survive) ---
leftover="$(grep -rIn -E '\{\{[A-Za-z0-9_]+\}\}' "$work" 2>/dev/null || true)"
if [ -n "$leftover" ]; then
	printf 'bootstrap: unreplaced template tokens remain (file:line):\n%s\n' "$leftover" >&2
	die "leftover tokens in generated content — add the missing token to the substitution list"
fi
leftover_paths="$(find "$work" -name '*{{*}}*' 2>/dev/null || true)"
if [ -n "$leftover_paths" ]; then
	printf 'bootstrap: unreplaced tokens in file paths:\n%s\n' "$leftover_paths" >&2
	die "leftover tokens in generated file paths"
fi

# --- H5 post-generation conformance self-check — IC-7 (prove output conformant)
scan_json="$_staging/repo-structure.json"
bash "$scan_script" --root "$work" --artifact-type "$atype" --artifact-dir "$artifact_dir" \
	>"$scan_json" || die "conformance scan of the generated tree failed"

summary="$(opa eval --data "$policy_dir" --input "$scan_json" --format json \
	'data.kellerai.oss.conformance.summary' 2>/dev/null |
	jq -c '.result[0].expressions[0].value')" ||
	die "opa eval failed during the conformance self-check"

allow="$(printf '%s' "$summary" | jq -r '.allow')"
if [ "$allow" != "true" ]; then
	printf 'bootstrap: generated tree FAILED the conformance self-check (%s):\n' "$summary" >&2
	opa eval --data "$policy_dir" --input "$scan_json" --format json \
		'data.kellerai.oss.conformance.errors' 2>/dev/null |
		jq -r '.result[0].expressions[0].value[]? | "  error: \(.rule) — \(.msg)"' >&2 || true
	die "conformance self-check failed — generated tree is not golden-conformant"
fi

# --- Publish: move the verified tree into place (H2) -------------------------
mkdir -p "$out"
cp -R "$work/." "$out/"

echo "bootstrap: scaffolded '$name' ($atype, $license) at $out"
echo "bootstrap: conformance self-check passed — $summary"
echo "next steps:"
echo "  cd $out && git init -b main"
echo "  lefthook install            # optional: install the pre-commit hook"
echo "  git add -A && git commit -m 'feat: initial commit'"
