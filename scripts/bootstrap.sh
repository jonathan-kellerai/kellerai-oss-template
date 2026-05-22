#!/usr/bin/env bash
# bootstrap.sh — scaffold a new kellerai-conformant repository from the
# template/ scaffold. Generation only: it does not git-init, commit, or push.
set -euo pipefail

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

usage() {
	cat <<'USAGE'
usage: bootstrap.sh --name NAME --artifact-type TYPE --license LICENSE \
                    --noun NOUN --out DIR [--validator V] [--artifact-dir D] \
                    [--owner OWNER] [--author AUTHOR] [--description TEXT]

  --artifact-type   one of: json-schema markdown-spec rego-policy rag-config
  --license         one of: Apache-2.0 CC-BY-4.0 MIT
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
	-h | --help) usage; exit 0 ;;
	*) echo "bootstrap: unknown argument: ${1:-}" >&2; usage; exit 2 ;;
	esac
done

script_dir="$(cd "$(dirname "$0")" && pwd)"
template_root="$(cd "$script_dir/.." && pwd)"
files_src="$template_root/template/_files"
licenses_src="$template_root/template/licenses"

err=0
[ -n "$name" ] || { echo "bootstrap: --name is required" >&2; err=1; }
[ -n "$out" ] || { echo "bootstrap: --out is required" >&2; err=1; }
case "$atype" in
json-schema | markdown-spec | rego-policy | rag-config) ;;
*) echo "bootstrap: --artifact-type must be one of json-schema markdown-spec rego-policy rag-config" >&2; err=1 ;;
esac
case "$license" in
Apache-2.0 | CC-BY-4.0 | MIT) ;;
*) echo "bootstrap: --license must be one of Apache-2.0 CC-BY-4.0 MIT" >&2; err=1 ;;
esac
[ -d "$files_src" ] || { echo "bootstrap: template files not found at $files_src" >&2; err=1; }
[ "$err" -eq 0 ] || { usage; exit 2; }

if [ -e "$out" ] && [ -n "$(ls -A "$out" 2>/dev/null || true)" ]; then
	echo "bootstrap: --out directory '$out' exists and is not empty" >&2
	exit 2
fi

case "$atype" in
json-schema) default_dir="schemas"; default_validator="ajv" ;;
markdown-spec) default_dir="specs"; default_validator="markdownlint" ;;
rego-policy) default_dir="conformance"; default_validator="opa" ;;
rag-config) default_dir="configs"; default_validator="ajv" ;;
esac
[ -n "$artifact_dir" ] || artifact_dir="$default_dir"
[ -n "$validator" ] || validator="$default_validator"
[ -n "$noun" ] || noun="artifact"
year="$(date +%Y)"

mkdir -p "$out"
cp -R "$files_src/." "$out/"

# Token substitution across every generated file.
find "$out" -type f | while IFS= read -r f; do
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
		"$f" >"$f.tmp" && mv "$f.tmp" "$f"
done

# Rename files whose paths still contain tokens (e.g. {{ARTIFACT_NOUN}}-bug.yml).
find "$out" -depth -type f -name '*{{*}}*' | while IFS= read -r f; do
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
done

# License body (verbatim; never tokenized).
cp "$licenses_src/$license.txt" "$out/LICENSE"

# Artifact directory + conformance marker.
mkdir -p "$out/$artifact_dir"
: >"$out/$artifact_dir/.gitkeep"

cat >"$out/.kellerai-oss.json" <<JSON
{
  "artifact_type": "$atype",
  "artifact_dir": "$artifact_dir",
  "primary_validator": "$validator",
  "owner": "$owner"
}
JSON

echo "bootstrap: scaffolded '$name' ($atype, $license) at $out"
echo "next steps:"
echo "  cd $out && git init -b main"
echo "  lefthook install            # optional: install the pre-commit hook"
echo "  git add -A && git commit -m 'feat: initial commit'"
