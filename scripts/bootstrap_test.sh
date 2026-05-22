#!/usr/bin/env bash
# bootstrap_test.sh — regression test for scripts/bootstrap.sh (H9 / IC-1..IC-7).
#
# Runs the bootstrap once per artifact type into a temp directory and asserts
# the generated tree is golden-conformant by construction:
#   - no unreplaced template tokens survive            (H4 / IC-2)
#   - opa check exits 0 and opa test passes            (H5 / IC-7)
#   - the conformance policy reports allow == true     (H5 / IC-7)
# It also exercises the fail-fast guards: input validation (H1 / IC-7),
# atomic generation (H2 / IC-1, IC-6) and the no-clobber guard (H3 / IC-6).
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
bootstrap="$script_dir/bootstrap.sh"
scan_script="$script_dir/scan-repo-structure.sh"
policy_dir="$repo_root/conformance"

pass=0
fail=0
workspace="$(mktemp -d "${TMPDIR:-/tmp}/bootstrap-test.XXXXXX")"
cleanup() { rm -rf "$workspace"; }
trap cleanup EXIT

ok() { printf 'PASS  %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL  %s\n' "$1"; fail=$((fail + 1)); }

# --- artifact-type matrix: every type must generate a conformant tree --------
types=(json-schema markdown-spec rego-policy rag-config)
for atype in "${types[@]}"; do
	out="$workspace/$atype"
	if ! "$bootstrap" \
		--name "test-$atype" \
		--artifact-type "$atype" \
		--license MIT \
		--noun rule \
		--description "Test artifact for $atype" \
		--out "$out" >"$workspace/$atype.log" 2>&1; then
		bad "$atype: bootstrap exited non-zero"
		cat "$workspace/$atype.log"
		continue
	fi

	# H4 — no unreplaced tokens in file content or in file paths.
	if grep -rIn -E '\{\{[A-Za-z0-9_]+\}\}' "$out" >/dev/null 2>&1 ||
		find "$out" -name '*{{*}}*' | grep -q .; then
		bad "$atype: leftover template tokens in generated tree"
	else
		ok "$atype: leftover-token scan clean"
	fi

	# H5 — opa check on the whole tree; opa test scoped to the artifact dir.
	# opa test must target the artifact directory (where rego lives): run over
	# the whole tree it would try to load every workflow YAML as a data
	# document and hit merge errors unrelated to conformance.
	if opa check "$out" >/dev/null 2>&1; then
		ok "$atype: opa check exit 0"
	else
		bad "$atype: opa check non-zero"
	fi
	adir="$(jq -r '.artifact_dir' "$out/.kellerai-oss.json")"
	if opa test "$out/$adir" >/dev/null 2>&1; then
		ok "$atype: opa test ($adir) PASS"
	else
		bad "$atype: opa test ($adir) non-zero"
	fi

	# H5 — conformance self-check: the generated tree must satisfy the policy.
	scan="$workspace/$atype.json"
	bash "$scan_script" --root "$out" --artifact-type "$atype" >"$scan"
	allow="$(opa eval --data "$policy_dir" --input "$scan" --format json \
		'data.kellerai.oss.conformance.summary' |
		jq -r '.result[0].expressions[0].value.allow')"
	if [ "$allow" = "true" ]; then
		ok "$atype: conformance self-check allow == true"
	else
		bad "$atype: conformance self-check allow == $allow"
	fi
done

# --- H1 input validation: invalid input must fail fast, before any write -----
if "$bootstrap" --name test --artifact-type bogus --license MIT --noun rule \
	--out "$workspace/bad-type" >/dev/null 2>&1; then
	bad "H1: invalid --artifact-type was accepted"
else
	ok "H1: invalid --artifact-type rejected"
fi

if "$bootstrap" --name "Bad Name" --artifact-type json-schema --license MIT --noun rule \
	--out "$workspace/bad-name" >/dev/null 2>&1; then
	bad "H1: invalid --name slug was accepted"
else
	ok "H1: invalid --name slug rejected"
fi

if "$bootstrap" --name test --artifact-type json-schema --license BOGUS --noun rule \
	--out "$workspace/bad-license" >/dev/null 2>&1; then
	bad "H1: invalid --license was accepted"
else
	ok "H1: invalid --license rejected"
fi

# H2 — a failed run must never leave a partial tree at --out.
if [ -e "$workspace/bad-name" ]; then
	bad "H2: partial tree left at --out after a failed run"
else
	ok "H2: no partial tree after a failed run"
fi

# --- H3 no-clobber: a non-empty --out is refused unless --force is passed ----
clobber="$workspace/clobber"
mkdir -p "$clobber"
: >"$clobber/sentinel"
if "$bootstrap" --name test --artifact-type json-schema --license MIT --noun rule \
	--out "$clobber" >/dev/null 2>&1; then
	bad "H3: non-empty --out overwritten without --force"
else
	ok "H3: non-empty --out refused without --force"
fi
if "$bootstrap" --name test --artifact-type json-schema --license MIT --noun rule \
	--out "$clobber" --force >/dev/null 2>&1; then
	ok "H3: --force overwrites a non-empty --out"
else
	bad "H3: --force did not overwrite a non-empty --out"
fi

# --- summary -----------------------------------------------------------------
printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
