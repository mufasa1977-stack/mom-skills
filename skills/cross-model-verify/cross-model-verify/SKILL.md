---
name: cross-model-verify
description: >
  Kill self-confirmation + style bias before you act on a claim: verify consequential
  claims/findings/decisions with INDEPENDENT judges from a DIFFERENT model family, each
  prompted to REFUTE, aggregated by a conservative self-testing gate. Use before an
  irreversible/costly action, before reporting a confident conclusion, or before executing
  a delegated agent's recommendation.
metadata:
  type: skill
  axis: self-verify           # OmniGod scorecard axis 11 (was 44/100)
  elite_flow: true            # prose wired into a self-testing gate
  gate: cross_model_verify.py
---

# cross-model-verify

## The gap this closes
A claim checked by the SAME model (or family) that produced it inherits that model's blind spots —
it tends to CONFIRM itself and confirm things phrased in its own style. That is exactly how a
"plausible but wrong" finding survives (see failures: verify-delegated-findings, measure-
requirement-not-proxy, self-catch). Real verification needs judges that don't share the author's
priors: a **different model family**, prompted to **refute**, aggregated **conservatively**.

## When to run it (triggers)
- About to take an **irreversible or costly** action based on a claim (delete/move/overwrite, spend,
  publish, send, kill a process, act on "this file is the wrong one").
- About to **report a confident conclusion** ("X is caused by Y", "this is done/verified", a number).
- About to **execute a delegated agent's recommendation** — verify its conclusion vs ground truth first.
- NOT needed for trivial/reversible steps — this costs tokens; reserve it for consequential claims.

## The method (do this, then gate)
1. State the claim as one refutable sentence + the concrete evidence for it.
2. Spawn **>= 3 independent verifiers** with the Agent tool, each prompted to **REFUTE** the claim
   ("Try to prove this WRONG. Default to `refuted` if you are not sure."). Each returns exactly one of
   `confirmed` | `refuted` | `uncertain`.
3. **Use >= 2 different model families** across the verifiers (Agent `model:` override — e.g. one
   `opus`, one `sonnet`, one `haiku`/`fable`). Same-family echo does NOT count; the gate enforces this.
   Prefer a family DIFFERENT from whoever produced the claim as at least one judge.
4. Aggregate with the gate:
   `python skills/cross-model-verify/cross_model_verify.py --verdicts opus:confirmed,sonnet:refuted,haiku:uncertain`
   - **KEEP** (exit 0): strict-majority confirmed across >=3 verifiers / >=2 families -> act.
   - **KILL** (exit 2): ties and majority-refute (uncertain counts as refuted) -> do NOT act; fix or drop the claim.
   - **INSUFFICIENT** (exit 3): too few verifiers or only one family -> add a cross-family judge, re-run.

## Decision rule (why it's conservative)
`uncertain` is treated as `refuted`; a **tie kills**; you need a *strict* majority of `confirmed` to
proceed. Bias is intentionally toward NOT acting on an unverified claim — cheaper than acting wrong.

## Self-test (this is what makes it ELITE-FLOW, not just prose)
`python skills/cross-model-verify/cross_model_verify.py --selftest`  -> exits 0 when the decision
rule is correct (8 cases: all-confirm KEEP, majority-refute KILL, tie KILL, uncertain->refuted,
single-family INSUFFICIENT, too-few-verifiers INSUFFICIENT). Run it after any edit to the rule.

## Why this is grounded (sources, not invented)
- **LLM self-preference / self-enhancement bias** ("Judging LLM-as-a-Judge", Zheng et al.): a model rates
  its own / same-family outputs higher -> a same-model check is not an independent check. Hence a DIFFERENT family.
- **Multi-agent debate & jury-of-judges** (Du et al. debate; panel-of-LLM-judges work): multiple independent
  judges + majority beat a single judge on factuality. Hence >=3 verifiers + majority rule.
- **Self-critique / adversarial refutation** (Constitutional-AI critique, red-team practice): prompting a judge
  to REFUTE (not "grade") surfaces the failure mode instead of rubber-stamping. Hence "default to refuted if unsure."
  (Bundled disciplines that encode these: [[multi-agent-systems-canon]], [[llm-alignment-research-canon]].)

## Portability
Self-contained: the gate (`cross_model_verify.py`) calls no model and reads no local paths — it is pure
decision logic + self-test, so it runs on any machine. Verify after copying with `--selftest` (expect exit 0).
