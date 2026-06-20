# LAAS conformance policy — quick reference

Machine-checkable conformance for **LLM-agent actions**. Companion to the repo's
`conformance/` policy (which checks repo *structure*); this one checks agent *actions* at
runtime. Normative prose: [`standard/LAAS.md`](../../standard/LAAS.md).

## Files

| File | Role |
|------|------|
| `data.json` | Single source of truth — obligation bundle, tier lattice, tolerances, floors |
| `laas.rego` | Policy — package `kellerai.laas.actions` |
| `laas_test.rego` | `opa test` suite (15 cases, one per obligation + pass/block/read-only) |
| `examples/action.ct4-blocked.json` | Sample decision record for `opa eval` |

## Input

The policy evaluates **one gate-produced decision record** — the agent's observed effect
surface, the gate's assigned tier, the verifier and its verdict, the enforcement-plane flags,
and the trace fields. The **gate** supplies the effect surface and tier; the agent's
`self_reported_ct` is informational and can never lower the tier. See
`examples/action.ct4-blocked.json` for the shape.

## Entry points

```text
data.kellerai.laas.actions.summary     # {bundle, expected_ct, effective_ct, errors, warnings, compliant}
data.kellerai.laas.actions.violations  # set of {obligation, severity, msg}
data.kellerai.laas.actions.error_ids   # set of error-severity obligation IDs
data.kellerai.laas.actions.compliant   # bool — true iff zero error-severity violations
```

## Run it

```bash
# Syntax check + test suite (expect: 15/15 PASS)
opa check laas.rego laas_test.rego
opa test . -v

# Evaluate a decision record against the bundle
opa eval -d laas.rego -d data.json \
  -i examples/action.ct4-blocked.json \
  'data.kellerai.laas.actions.summary' --format pretty
```

The bundled example is a **CT4 external transfer the gate blocked** (verifier abstained) — it is
conformant via the block path (`compliant: true`). Flip `"bundle_signed": true` to `false` in the
input and re-run to see `LAAS-OBL-ENF-001` fire and `compliant` drop to `false`.

## CI wiring (proposed)

A reusable workflow mirroring `.github/workflows/conformance.yml` runs `opa test` on this
directory and `opa eval` against a stream/sample of decision records. `error`-severity
violations block; `warning`-severity are reported. Pin to a commit SHA, not a branch.

> Verified on OPA 1.17.1. The conformance predicate references only declared trace fields, so it
> is mechanically evaluable — see `standard/LAAS.md` §5.
