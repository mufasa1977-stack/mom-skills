---
name: llm-reasoning-frameworks-canon
description: Canonical reference for LLM agent reasoning frameworks — Chain of Thought (CoT), ReAct, Tree of Thoughts (ToT), Graph of Thoughts (GoT), ReWOO, Reflexion, Self-Refine, Self-Consistency, LATS, Constitutional AI, Self-Discover, Algorithm of Thoughts, Skeleton of Thoughts, Plan-and-Solve, plus the 2024-2026 "thinking model" trend (o1/o3, Claude extended thinking, Gemini Deep Think, DeepSeek R1). Includes when-to-use-which decision matrix, failure modes, and concrete mapping to Forbidden Files Stage -1 / Stage 0 / Production Block / self-critique cycle. Triggers when designing agent reasoning loops, choosing prompt scaffolds, debugging hallucinated chains, picking between fast-intuition and slow-deliberation models, or grounding any "think before acting" decision.
---

# LLM Reasoning Frameworks Canon

Locked 2026-05-23. Operating manual for "how should the agent think before it acts."

## 14 Frameworks

1. **Chain of Thought (CoT)** — Wei 2022 arXiv:2201.11903. Few-shot exemplars OR zero-shot "let's think step by step." GSM8K PaLM 540B 18% → 57%. HURTS on small models <60B, lookup tasks, or implicit-pattern tasks.

2. **Tree of Thoughts (ToT)** — Yao 2023 arXiv:2305.10601. Generate b candidates per step + evaluate + search (DFS/BFS). Game of 24: CoT 4% → ToT 74%. Branches explode without pruning.

3. **Graph of Thoughts (GoT)** — Besta 2023 arXiv:2308.09687. DAG generalization of ToT — aggregate / refine / generate. 62% quality lift + 31% fewer tokens vs ToT on sort tasks.

4. **ReAct (Reasoning + Acting)** — Yao 2022 arXiv:2210.03629. Interleaved Thought → Action → Observation. **Industry standard 2024-2026**. HotpotQA +4-8% F1 over CoT. ALFWorld +34%.

5. **ReWOO** — Xu 2023 arXiv:2305.18323. Three modules: Planner emits full plan with placeholders, Worker fills, Solver synthesizes. **5× token efficiency vs ReAct** on linear plans. Forbidden Files parallel agent dispatch = ReWOO at orchestration layer.

6. **Reflexion** — Shinn 2023 arXiv:2303.11366. Verbal RL — agent reflects on failures, stores in episodic memory, re-attempts. HumanEval GPT-4 80 → 91%. **Forbidden Files Item #43 = Reflexion with persistent cross-session memory.**

7. **Self-Refine** — Madaan 2023 arXiv:2303.17651. Generate → Feedback (specific) → Refine. 20%+ gain on creative tasks. **Forbidden Files Item #42 = Self-Refine iter=1.**

8. **Self-Consistency** — Wang 2022 arXiv:2203.11171. Sample N CoT trajectories + majority vote. GSM8K PaLM 56.5% → N=40: 74.4%. **Forbidden Files 30 parallel agents = Self-Consistency at orchestration.**

9. **LATS (Language Agent Tree Search)** — Zhou 2023 arXiv:2310.04406. MCTS over agent trajectories. WebShop +12%, HumanEval 92.7%. 10-100× tokens vs ReAct — reserve for high-value high-difficulty.

10. **Constitutional AI / RLAIF** — Bai 2022 arXiv:2212.08073. Two-stage SL + RL alignment via principles. Inference-time analog: stable system-prompt constitution + self-critique step. **Forbidden Files PRICELESS rules = personal constitution.**

11. **Self-Discover** — Zhou 2024 arXiv:2402.03620. Compose reasoning structure from ~39 atomic modules. 32% gain on BBH. **Forbidden Files scene-type canons = discovered reusable structures.**

12. **Algorithm of Thoughts** — Sel 2023 arXiv:2308.10379. Full algorithmic search trace in ONE prompt. Trades calls-per-task for tokens-per-call.

13. **Skeleton of Thoughts** — Ning 2023 arXiv:2307.15337. Skeleton stage outlines, point-expand stage in parallel. 2-2.5× faster wall-clock. **Forbidden Files cut sheet (narration skeleton + per-beat parallel generation).**

14. **Plan-and-Solve+** — Wang 2023 arXiv:2305.04091. Replace "let's think step by step" with "let's understand and devise a plan, then execute step by step." 3-5% absolute over zero-shot CoT.

## The 2024-2026 Thinking Model Trend

Models trained to emit reasoning natively with extended internal thinking:
- **OpenAI o1 (Sep 2024) / o3 / o4-mini** — large-scale RL on CoT, hidden reasoning tokens
- **Claude 3.7 Sonnet / 4 / 4.5 / 4.6 / 4.7** — extended thinking, developer-controlled budget, visible in API
- **Gemini 2.5 Pro / Deep Think** — parallel reasoning streams converge
- **DeepSeek R1 (Jan 2025 arXiv:2501.12948)** — open-weights, visible CoT, RL with rule-based rewards
- **Qwen QwQ-32B / Qwen3** — Alibaba open reasoning

**Common pattern**: train the model to internalize what prompt engineering externalized. Better quality at 10-100× inference cost. Many prompt-level techniques (CoT, Self-Consistency, ToT, Self-Refine) **partially obsoleted** — model does internally.

**Survivors**: ReAct (still required for tools), Reflexion (cross-episode memory = harness job), ReWOO (orchestration efficiency), Self-Discover (per-task scaffold selection).

## Decision Matrix

| Situation | Framework |
|---|---|
| Simple Q&A / lookup | None (or zero-shot CoT if uncertain) |
| Multi-step arithmetic/logic no tools | Zero-shot CoT or Plan-and-Solve+ |
| Multi-step with tools / retrieval | **ReAct** |
| Need to explore + backtrack | ToT (DFS cheap, BFS thorough) |
| Sub-problems that combine | Graph of Thoughts |
| Tool calls expensive + linear plan | **ReWOO** |
| Iterative improvement on output | **Self-Refine** |
| Repeated attempts at same task type | **Reflexion** |
| High-stakes single answer | Self-Consistency (N=5-40) |
| Long-horizon hard problem | LATS |
| Choosing scaffold per task | Self-Discover |
| Single-window search | Algorithm of Thoughts |
| Listy answer + latency matters | Skeleton of Thoughts |
| Long-running agent on a mission | Constitutional principles + Self-Refine |
| Reasoning model available | Native thinking + ReAct for tools (don't double-scaffold) |

## Forbidden Files Application

| Practice | Reasoning Framework |
|---|---|
| Stage 0 four-block plan | **CoT** with structured output + **ReWOO** at research layer |
| Item #42 pre-emptive critique | **Self-Refine** iter=1 |
| Item #43 meta-pattern abstraction → MEMORY/skill | **Reflexion** with persistent cross-session memory |
| 30 parallel agent dispatch | **Self-Consistency** at orchestration + **ReWOO** shape |
| Genius skill 10x questions | Multi-perspective forced sampling |
| Cinematic-canon-research-protocol (Rule 6j) | **Self-Discover** (composed structure) |
| Reenactment-preflight-gate ENV/SUBJ/TONE/CAMERA/LENS | **Plan-and-Solve+** |
| Autonomous-production-director (Rule 6i) | **ReAct** with high autonomy |
| Browser-first-production (Rule 6g) | **ReAct** in tool layer |
| Storyboard before motion render | **Skeleton of Thoughts** at production level |
| Self-improving-production-pipeline | **Constitutional AI** at system level — Tariq feedback trains new constitutions |

## Failure Modes

- **CoT hallucinates confident chains.** Wrong chain reads like right one (Turpin 2023 arXiv:2305.04388). Verify with oracle.
- **ToT branches explode without pruning.** b=5 d=4 = 625 states.
- **Reflexion confirmation bias.** "Should have tried harder" — force named different strategy; escalate after N=3.
- **Multi-agent debate converges on shared error.** Heterogeneous stack, adversarial agent, external verifier.
- **Faithfulness gap** — visible CoT may not reflect actual computation. Don't trust as audit trail without external verification.
- **Over-scaffolding hurts.** Match scaffold complexity to task difficulty.

## System 1 vs System 2 (Kahneman 2011)

- **System 1** = base model forward pass (instant, pattern-match)
- **System 2** = extended thinking / CoT / tool use / multi-step scaffolds
- Genius = both, routed dynamically. Modern reasoning models (o3, Claude extended thinking, R1) route by thinking budget

**Practical dual-system architecture**: Haiku-class for triage + simple Q&A → Sonnet-class for production + browser → Opus / o3 / extended-thinking for hard reasoning + synthesis.

## Sources (36)

Wei 2022 CoT arXiv:2201.11903; Kojima 2022 Zero-shot CoT arXiv:2205.11916; Wang 2022 Self-Consistency arXiv:2203.11171; Yao 2022 ReAct arXiv:2210.03629; Yao 2023 ToT arXiv:2305.10601; Besta 2023 GoT arXiv:2308.09687; Xu 2023 ReWOO arXiv:2305.18323; Shinn 2023 Reflexion arXiv:2303.11366; Madaan 2023 Self-Refine arXiv:2303.17651; Zhou 2023 LATS arXiv:2310.04406; Bai 2022 Constitutional AI arXiv:2212.08073; Zhou 2024 Self-Discover arXiv:2402.03620; Sel 2023 AoT arXiv:2308.10379; Ning 2023 SoT arXiv:2307.15337; Wang 2023 Plan-and-Solve arXiv:2305.04091; Turpin 2023 CoT faithfulness arXiv:2305.04388; Yuan 2024 Self-Rewarding LMs arXiv:2401.10020; Lightman 2023 Process supervision arXiv:2305.20050; Hao 2023 RAP arXiv:2305.14992; Schick 2023 Toolformer arXiv:2302.04761; Qin 2023 ToolLLM arXiv:2307.16789; AutoGPT 2023; OpenAI o1 system card 2024; DeepSeek R1 arXiv:2501.12948; Anthropic Claude 3.7 extended thinking; Gemini 2.5 technical report; Snell 2024 Test-Time Compute arXiv:2408.03314; Brown 2024 Large Language Monkeys arXiv:2407.21787; Anthropic Constitutional Classifiers arXiv:2501.18837; Qwen3 technical report; Kahneman Thinking Fast and Slow 2011.

## PAIRS WITH

ai-autonomy-research-canon, llm-memory-architectures-canon, skill-abstraction-canon, expert-learning-science-canon, genius, autonomous-production-director, self-improving-production-pipeline, reenactment-preflight-gate, master-prompt-engineering.
