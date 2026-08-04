---
name: llm-alignment-research-canon
description: SOTA reference on LLM alignment training — pre-training (Common Crawl/Pile/FineWeb/scaling laws/MoE), SFT + PEFT (LoRA/QLoRA/DoRA), RLHF (InstructGPT/PPO), RLAIF Constitutional AI (Anthropic), DPO (Rafailov 2023), GRPO (DeepSeek R1), Self-Rewarding LMs (Meta 2024), Process Reward Models, and how the Forbidden Files skill+memory system maps to personal Constitutional AI. Triggers on "alignment training", "RLHF", "DPO", "Constitutional AI", "fine-tuning", "RLAIF", "how does Claude work", "how to align Claude to my house style", "PRICELESS rules as constitution".
---

# LLM Alignment Research Canon

Locked 2026-05-23. Not for training models — for understanding what makes AI behave well + how that informs prompting/skill design.

## The Stack

### Pre-training
- Common Crawl + The Pile + RedPajama + FineWeb + Dolma
- Scaling laws — Kaplan 2020 / Hoffmann (Chinchilla) 2022
- Mixture-of-Experts — Mixtral 8x7B, GPT-4, DeepSeek V3, DBRX

### Supervised Fine-Tuning (SFT)
- Instruction tuning: FLAN, Alpaca, Dolly, ShareGPT
- PEFT techniques: LoRA (Hu 2021), QLoRA (Dettmers 2023), DoRA (Liu 2024)

### RLHF (Reinforcement Learning from Human Feedback)
- InstructGPT 2022 — the original
- PPO (Proximal Policy Optimization) for reward model
- Reward model collapse + KL-divergence penalty
- Human labeler bias (sycophancy, verbosity, hedging)

### RLAIF (RL from AI Feedback)
- **Constitutional AI** — Anthropic Bai 2022 arXiv:2212.08073
- 7-stage process: SL phase (model generates → self-critiques per constitution → revises → fine-tune on revised pairs) + RL phase (model picks which response better follows constitution → reward model → policy RL)

### DPO (Direct Preference Optimization)
- Rafailov 2023 arXiv:2305.18290
- Skips reward model, optimizes directly on preferences
- More stable than PPO, **dominant alignment technique 2024-2026**
- Variants: IPO, KTO, ORPO, SimPO

### GRPO (Group Relative Policy Optimization)
- DeepSeek R1 reasoning model (arXiv:2501.12948)
- Group-relative rewards
- Reasoning emergence

### Self-Rewarding Language Models
- Meta 2024 (Yuan et al arXiv:2401.10020)
- Models generate + judge own outputs
- Iterative self-improvement loop
- **Ceiling problem**: without external eval anchor, model can drift into self-rewarding collapse

### Process Reward Models (PRM)
- Lightman 2023 arXiv:2305.20050
- Reward per reasoning STEP, not just final answer
- Critical for chain-of-thought quality

## How Forbidden Files is Doing Personal Constitutional AI

The user's skill+memory architecture IS a working personal-scale Constitutional AI deployment:

| Constitutional AI element | Forbidden Files mapping |
|---|---|
| The policy (LLM) | Claude |
| SFT corpus | Skill files (examples of correct behavior) |
| Written constitution | PRICELESS rules 6a-6l |
| Process Reward Model | Reenactment-preflight-gate (rewards per step in production pipeline) |
| RLAIF self-critique loop | `self-improving-production-pipeline` (Tariq feedback → skill update) |
| External eval anchor | Tariq's executive-producer review (prevents Self-Rewarding LM collapse — Yuan 2024 ceiling) |
| Reward hacking defense | Item #42 pre-emptive self-critique + Item #38 end-to-end watch gate |

## Recognizing Constitutional Refusals in Prompts

The "I'll help with X but not Y" pattern is the alignment seam. Visible signs:
- Specific phrasings consistent across requests
- Helpfulness pivot ("I can help instead with...")
- Boundary respect (mid-sentence stop)

**Working with the alignment grain (not against it)**:
- Use the model's helpfulness drive constructively
- Don't try to jailbreak — dead end (Anthropic Constitutional Classifiers arXiv:2501.18837)
- Counter RLHF labeler bias: ask for terse direct answers (sycophancy/verbosity bias)
- Hedging bias: ask for confidence levels separately from claims

## Mapping Forbidden Files Items #36-#44 to Constitutional Principles

| Item | Constitutional principle |
|---|---|
| #36 Verify before assume (audio playback gate) | Honesty — don't claim what you haven't checked |
| #37 Signature placement gate | Process reward (per-step verification) |
| #38 End-to-end watch gate | Honesty — "shipped" requires actual verification |
| #39 Audio-driven lipsync default | Avoid cheap fakery (alignment with "be truly useful") |
| #40 HARD-STOP AUTO-INVOKE GATE | Sheets before generation = constitutional preflight |
| #41 Pre-turn learning review | Recall before action (Reflexion built into constitution) |
| #42 Pre-emptive self-critique | Self-Refine before send = Bai 2022 phase A step 3 |
| #43 Meta-pattern abstraction | Iterative RLAIF refinement |
| #44 Self-directed exploratory learning | Genius mode = proactive constitutional improvement |

## Future Direction

- DPO from synthetic preferences
- Self-improving model loops (with external anchors to prevent collapse)
- Constitutional Classifiers as runtime safety (Anthropic 2025)
- Personal-scale alignment via skill files — exactly what Forbidden Files is doing

## Sources (33)

Bai et al Constitutional AI 2022 arXiv:2212.08073; Ouyang et al InstructGPT 2022 arXiv:2203.02155; Rafailov DPO 2023 arXiv:2305.18290; DeepSeek R1 2025 arXiv:2501.12948; Yuan Self-Rewarding 2024 arXiv:2401.10020; Lightman PRM 2023 arXiv:2305.20050; Anthropic Constitutional Classifiers 2025 arXiv:2501.18837; Hu LoRA 2021 arXiv:2106.09685; Dettmers QLoRA 2023 arXiv:2305.14314; Liu DoRA 2024 arXiv:2402.09353; Kaplan scaling laws 2020 arXiv:2001.08361; Hoffmann Chinchilla 2022 arXiv:2203.15556; Mixtral 8x7B technical report; DeepSeek V3 technical report; Anthropic Claude character training; OpenAI Model Spec; Bai HH (Helpful Harmless Honest) 2022 arXiv:2204.05862; Stiennon summarization RLHF 2020 arXiv:2009.01325; Christiano deep RL from human prefs 2017 arXiv:1706.03741; FLAN Wei 2022; Alpaca Stanford 2023; Dolly Databricks 2023; Common Crawl; The Pile EleutherAI; RedPajama; FineWeb HuggingFace; Phi Microsoft synthetic textbooks; Llama 3 technical report; Gemini technical reports; OpenAI o1 system card; Karpathy intro to LLMs; Anthropic Sleeper Agents 2024; Hubinger mesa-optimization.

## PAIRS WITH

ai-autonomy-research-canon, llm-reasoning-frameworks-canon, expert-learning-science-canon, genius, priceless, self-improving-production-pipeline, reenactment-preflight-gate, master-prompt-engineering.
