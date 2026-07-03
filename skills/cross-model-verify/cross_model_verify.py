#!/usr/bin/env python3
"""
cross_model_verify.py  —  the executable, self-testing gate for the `cross-model-verify` skill.

WHY: a claim verified by the SAME model that produced it inherits that model's blind spots and
style bias (self-confirmation). Real verification needs INDEPENDENT judges from a DIFFERENT model
family, each prompted to REFUTE, aggregated with a conservative (default-to-refuted) rule.

This script does NOT call any model. It is the DECISION LAYER + self-test:
  - you spawn N adversarial verifiers (via the Agent tool, using different `model:` families),
    each returning confirmed | refuted | uncertain,
  - you feed their verdicts here, and it returns the gated decision KEEP / KILL / INSUFFICIENT.

USAGE
  python cross_model_verify.py --verdicts opus:confirmed,sonnet:refuted,haiku:uncertain
  python cross_model_verify.py --verdicts confirmed,refuted,confirmed --min-verifiers 3 --min-families 2
  python cross_model_verify.py --selftest        # unit-tests the decision rule; exit 0 = all pass

EXIT CODES:  0 = KEEP (claim survived)   2 = KILL (refuted)   3 = INSUFFICIENT (add verifiers/families)
"""
import argparse, sys

VALID = {"confirmed", "refuted", "uncertain"}


def decide(verdicts, min_verifiers=3, min_families=2):
    """verdicts: list of (family, verdict). Returns (decision, exit_code, reason, tally)."""
    if not verdicts:
        return "INSUFFICIENT", 3, "no verifiers supplied", {}
    families = {f for f, _ in verdicts if f}
    # conservative: uncertain counts as refuted ("default to refuted if unsure")
    confirmed = sum(1 for _, v in verdicts if v == "confirmed")
    refuted = sum(1 for _, v in verdicts if v in ("refuted", "uncertain"))
    tally = {"confirmed": confirmed, "refuted(+uncertain)": refuted,
             "verifiers": len(verdicts), "distinct_families": len(families)}
    if len(verdicts) < min_verifiers:
        return ("INSUFFICIENT", 3,
                f"only {len(verdicts)} verifier(s); need >= {min_verifiers}", tally)
    if len(families) < min_families:
        return ("INSUFFICIENT", 3,
                f"only {len(families)} model family/families; need >= {min_families} "
                f"(cross-family is the whole point — add a different model as judge)", tally)
    # need a STRICT majority of confirmed to KEEP; ties and majority-refute KILL
    if confirmed > refuted:
        return "KEEP", 0, f"strict-majority confirmed ({confirmed} vs {refuted})", tally
    return "KILL", 2, f"not a strict-majority confirm ({confirmed} vs {refuted}) — refuted", tally


def parse_verdicts(s):
    out = []
    for tok in s.split(","):
        tok = tok.strip()
        if not tok:
            continue
        if ":" in tok:
            fam, v = tok.split(":", 1)
            fam, v = fam.strip().lower(), v.strip().lower()
        else:
            fam, v = "", tok.strip().lower()
        if v not in VALID:
            raise SystemExit(f"bad verdict '{v}' (must be one of {sorted(VALID)})")
        out.append((fam, v))
    return out


def selftest():
    cases = [
        # (verdicts, min_verifiers, min_families, expected_decision)
        ([("opus", "confirmed"), ("sonnet", "confirmed"), ("haiku", "confirmed")], 3, 2, "KEEP"),
        ([("opus", "confirmed"), ("sonnet", "refuted"), ("haiku", "refuted")], 3, 2, "KILL"),
        ([("opus", "confirmed"), ("sonnet", "refuted")], 2, 2, "KILL"),          # 1-1 tie -> KILL
        ([("opus", "uncertain"), ("sonnet", "confirmed"), ("haiku", "confirmed")], 3, 2, "KEEP"),
        ([("opus", "confirmed"), ("opus", "confirmed"), ("opus", "confirmed")], 3, 2, "INSUFFICIENT"),  # 1 family
        ([("opus", "confirmed"), ("sonnet", "confirmed")], 3, 2, "INSUFFICIENT"),  # too few verifiers
        ([("opus", "uncertain"), ("sonnet", "uncertain"), ("haiku", "uncertain")], 3, 2, "KILL"),
        ([], 3, 2, "INSUFFICIENT"),
    ]
    ok = True
    for i, (v, mv, mf, exp) in enumerate(cases, 1):
        dec, _, reason, _ = decide(v, mv, mf)
        status = "ok " if dec == exp else "FAIL"
        if dec != exp:
            ok = False
        print(f"  [{status}] case {i}: got {dec:<12} expected {exp:<12} ({reason})")
    print("SELFTEST", "PASS" if ok else "FAIL")
    return 0 if ok else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--verdicts", help="comma list, each 'family:verdict' or 'verdict' (confirmed|refuted|uncertain)")
    ap.add_argument("--min-verifiers", type=int, default=3)
    ap.add_argument("--min-families", type=int, default=2)
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        sys.exit(selftest())
    if not a.verdicts:
        ap.error("give --verdicts or --selftest")
    v = parse_verdicts(a.verdicts)
    dec, code, reason, tally = decide(v, a.min_verifiers, a.min_families)
    print(f"DECISION: {dec}")
    print(f"reason:   {reason}")
    print(f"tally:    {tally}")
    sys.exit(code)


if __name__ == "__main__":
    main()
