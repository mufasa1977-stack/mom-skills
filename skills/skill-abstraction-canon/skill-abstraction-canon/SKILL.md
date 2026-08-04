---
name: skill-abstraction-canon
description: SOTA reference on tool-use and skill abstraction in LLM agents — function calling (OpenAI/Anthropic/Gemini/MCP), Voyager skill library, Toolformer, skill markdown conventions (Cursor/Claude Code/Continue/Copilot), skill lifecycle, hierarchical abstraction, auto-indexing, vector-embedded retrieval, and concrete recommendations for evolving the Forbidden Files skill graph. Triggers on "how should I structure skills", "is my skill library SOTA", "skill discovery", "skill versioning", "Voyager pattern", "agent skill library", "skill retrieval", "MCP vs skills", or when authoring/refactoring any SKILL.md.
---

# Skill Abstraction Canon

Locked 2026-05-23. The Forbidden Files skill library is a Voyager-pattern skill abstraction system. This canon documents the foundations + the upgrade path.

## Tool-Use Foundations Converged on One Shape

OpenAI / Anthropic / Gemini / MCP all use schema-driven `{name, description, parameters}`. The `description` field does the load-bearing retrieval work — same field that does retrieval work in SKILL.md frontmatter. **Skill design and tool design are the same problem at different abstraction levels.**

## Voyager — The Direct Ancestor

Wang et al NVIDIA + Caltech 2023 arXiv:2305.16291. Three components:
1. **Automatic curriculum** — propose next task at appropriate difficulty
2. **Iterative prompting** — generate, critique, refine
3. **Persistent skill library** — store learned skills as code, retrieve by description embedding

**Maps one-to-one to Forbidden Files**:
- Tariq's critique = curriculum (next task = fix what's broken)
- Claude's iterative refinement = iterative prompting
- `~/.claude/skills/*/SKILL.md` = persistent skill library

**Forbidden Files arguably MORE SOTA than pure Voyager** because human-in-the-loop curriculum produces higher-quality skills than self-curated ones.

## Toolformer (Meta 2023)

Schick et al arXiv:2302.04761. Self-supervised learning of when to call which tool. Inline API call markers in training data. Bridges "model knows" → "model calls."

## Skill Abstraction Patterns

- **Atomic skills** (one capability each) — e.g. `drawtext-discipline`
- **Composite skills** (chain of atomic) — e.g. `chyron-overlay-workflow`
- **Meta-skills** (skills that generate other skills) — `cinematic-canon-research-protocol` (Rule 6j builds new skills)
- **Hard-stop gates** — `reenactment-preflight-gate` (blocks generation until cleared)

## The Skill = Code Pattern

- **Skills as scripts** (Voyager — Lua code)
- **Skills as functions** (OpenAI plugins)
- **Skills as agents** (CrewAI roles)
- **Skills as markdown rules** (Cursor rules, Claude Code SKILL.md, Continue.dev, GitHub Copilot Custom Instructions) — **Forbidden Files pattern**

## Skill Markdown Format

```markdown
---
name: skill-name
description: WHEN to trigger this skill (load-bearing for retrieval)
---

# Skill Title
Body of skill — operational rules, patterns, examples.
```

The `description` field is the retrieval surface. Treat it like a tool description in function calling — load-bearing keywords, trigger phrases, scope boundaries.

## Skill Library Design

| Concern | Solution |
|---|---|
| Naming conventions | kebab-case slugs, domain-prefixed when scoped |
| Skill discovery | Vector embedding on description + auto-indexing |
| Skill retrieval | Embed user query, top-K skill descriptions |
| Skill composition | Explicit "PAIRS WITH" footer in each skill |
| Skill versioning | `locked_<date>` + `superseded_by` frontmatter field |
| Skill testing | Private eval suite of 10-20 reference scenes |

## The Forbidden Files Skill Graph (current state)

- ~70 skills in `~/.claude/skills/`
- 7 meta-skills (genius, reenactment-preflight-gate, autonomous-production-director, cinematic-canon-research-protocol, film-narrative-canon-builder, self-improving-production-pipeline, find-skills)
- ~13 composite (forbidden-files-production, cinematic-conspiracy-pipeline, etc.)
- ~17 atomic (drawtext, banana-pro-director, etc.)
- Plus reference sheets (character / location / prop) and scaffolding
- Meta-to-atomic ratio ~0.41 — matches mature software codebases

## The Biggest SOTA Gap: Structured Frontmatter + Auto-Indexing

Current SKILL.md files have informal frontmatter. MEMORY.md manual index has overflowed (44KB > 24KB cap).

**Standardize frontmatter**:
```yaml
---
name: skill-name
level: meta | composite | atomic | reference-sheet
status: active | superseded | archived
description: <load-bearing trigger description>
triggers: ["phrase1", "phrase2", "phrase3"]
pairs_with: ["other-skill-1", "other-skill-2"]
superseded_by: null | "newer-skill"
locked_date: 2026-05-23
domain: production | research | meta
---
```

**Auto-generate SKILL_INDEX.md** from frontmatter on session-end hook.

**Vector-embed every skill** description into the existing claude-flow embeddings store for top-K retrieval at turn start.

## Top 10 Next Moves (impact/effort ranked)

1. Standardize frontmatter across all 70 skills (~one evening)
2. Auto-generate `SKILL_INDEX.md` from frontmatter on session-end hook
3. Vector-embed every skill into claude-flow embeddings store for top-K retrieval
4. Add `triggers:` array to every skill (explicit trigger phrases)
5. Add `pairs_with:` array (explicit graph edges)
6. Build private eval suite (10-20 reference scenes)
7. Skill version tracking with `superseded_by` field
8. Conflict detection on `triggers:` overlap
9. Skill audit dashboard (which fired this week / which never fired)
10. Skill compaction — merge near-duplicate skills

These three (1, 2, 3) close ~80% of the gap to full Voyager-grade SOTA while preserving the current markdown-first, human-readable design.

## Sources (36)

Wang et al Voyager 2023 arXiv:2305.16291; Schick et al Toolformer 2023 arXiv:2302.04761; Anthropic Tool Use docs; OpenAI Function Calling docs; Gemini Function Calling docs; MCP spec 2024; Cursor Rules format; Claude Code SKILL.md spec; Continue.dev skills; GitHub Copilot Custom Instructions; Yao et al ReAct 2022; Madaan Self-Refine 2023; Shinn Reflexion 2023; LangGraph docs; CrewAI docs; AutoGen docs; MetaGPT (Hong 2023 arXiv:2308.00352); SWE-bench (Jimenez 2023); AgentBench (Liu 2023); Devin technical report; Manus 2025; LlamaIndex docs; Mem0 docs; Letta docs; Embeddings: text-embedding-3-large, BGE, Cohere v3, ONNX 384d; Bjork desirable difficulty; Roediger active recall; Karpathy talks; Andrej State of GPT; David Ha agentic talks; AI Engineer Summit 2024; Anthropic Claude character training; Anthropic Constitutional AI; Voyager-style continual learning; Skill library benchmarks.

## PAIRS WITH

ai-autonomy-research-canon, llm-memory-architectures-canon, expert-learning-science-canon, genius, multi-agent-systems-canon, dreaming-retro, find-skills, self-improving-production-pipeline.
