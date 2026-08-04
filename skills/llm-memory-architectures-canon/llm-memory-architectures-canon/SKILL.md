---
name: llm-memory-architectures-canon
description: SOTA reference on memory architectures for LLM agents — working/short-term/episodic/semantic/procedural/meta-memory hierarchy, vector DBs (Pinecone/Weaviate/Qdrant/Chroma/HNSW), memory frameworks (MemGPT/Letta/Mem0/Zep/Graphiti/LangChain Memory/LlamaIndex), retrieval strategies (vector/hybrid/rerank/MMR/temporal decay), and the human-memory analogue (Tulving episodic/semantic, Squire declarative/procedural). Maps to the Forbidden Files MEMORY.md + claude-flow memory_store + skill file pattern. Triggers on "memory upgrade", "long-term memory", "cross-session memory", "MEMORY.md too big", "auto-categorize memory", "vector search", "retrieval-augmented", "MemGPT", "Zep", "Mem0", "episodic memory", "lifelong learning".
---

# LLM Memory Architectures Canon

Locked 2026-05-23. The memory hierarchy in LLM agents + the SOTA frameworks + the Forbidden Files upgrade path.

## The Memory Hierarchy (6 layers)

| Layer | Function | Forbidden Files implementation today |
|---|---|---|
| Working memory | Current task scratchpad | Context window (200K Claude / 2M Gemini) |
| Short-term scratch | Cross-turn within session | In-context conversation |
| Episodic | Past interactions, what happened | `feedback_*.md` files + claude-flow memory_store namespace |
| Semantic | Facts, knowledge | MEMORY.md index entries |
| Procedural | Skills, how to do things | SKILL.md files in `~/.claude/skills/` |
| Meta-memory | Memory about memory | MEMORY.md index of indexes |

## Vector Database Memory

- **Pinecone** — managed, scalable, costly
- **Weaviate** — open-source, GraphQL
- **Qdrant** — open-source, Rust-fast
- **Chroma** — Python-native, simple
- **Milvus** — enterprise-scale
- **LanceDB** — embedded, fast
- **HNSW** — the algorithm under claude-flow (Hierarchical Navigable Small World, Malkov 2016)

**Embedding models**: OpenAI text-embedding-3-large (3072d), Anthropic Claude embed, BGE-large (Beijing Academy AI), Cohere embed-v3, ONNX local models (claude-flow uses 384d ONNX = local, free, ~85-90% of cloud SOTA quality).

## Memory Frameworks for Agents

### MemGPT / Letta (Berkeley 2023)
Packer et al arXiv:2310.08560. OS-paging-style memory — agent has "main context" + "external storage", explicit functions to page in/out. **Letta** (rebranded MemGPT) is production-grade.

### Mem0
Universal AI memory layer with **auto-categorization** + **contradiction detection** + **smart consolidation**. Decides what to remember automatically vs requiring explicit store calls.

### Zep
arXiv:2501.13956. **Temporal knowledge graph** for agents — every fact has `valid_from` / `valid_to` timestamps. Solves the "facts change over time" problem (e.g. president changes, but old president still relevant for episodes about that era).

### Graphiti (Zep's open-source kernel)
Relationship-aware graph memory. Beats pure vector when entity relationships matter.

### LangChain Memory
BufferMemory, SummaryMemory, EntityMemory, KGMemory — modular building blocks. Most production agents use a combination.

### LlamaIndex Memory
TreeIndex hierarchical summarization (chunk → section → chapter → book pattern). Good for very long-term agent memory.

### claude-flow memory_store (Tariq has this)
HNSW + ONNX 384d embeddings. Local, free, cross-session-persistent. Namespaced (`patterns`, `episodes`, `decisions`, `feedback`). **The substrate is right** — Forbidden Files should borrow patterns from Mem0 (auto-categorize) + Zep (temporal) + LlamaIndex (hierarchical summarize) WITHOUT switching wholesale.

## Retrieval Strategies (ranked by quality)

1. **Pure vector similarity** — simple, fast, misses keyword-specific queries
2. **Hybrid (vector + BM25 keyword)** — RRF fusion (Cormack 2009) — closes the "Rule 6j" / "v11.5" named-identifier gap
3. **+ Re-ranking** — bge-reranker-v2-m3 ONNX adds ~80ms but measurable quality jump
4. **+ Time-decay** — recent memories weighted higher
5. **+ MMR** (Maximal Marginal Relevance, Carbonell 1998) — prevents top-k returning 10 near-duplicates
6. **Smart Retrieval pipeline** — query expansion + fusion + diversity + recency boost (claude-flow has this via `smart=true`)

## Memory Writing Strategies

- **Every interaction** (cheap, noisy)
- **Salient events only** (curated — what Forbidden Files does today)
- **Auto-summarization after N turns**
- **Manual `memory_store` when human flags importance** (current pattern)
- **Reflection-based** — agent decides what's worth remembering (Reflexion pattern, ideal for upgrade)

## Memory Compression + Summarization

- **Hierarchical summarization** — chunk → section → chapter → book (LlamaIndex pattern)
- **Concept extraction** — NER + entity linking
- **Episodic abstraction** — specific event → general lesson (Forbidden Files Item #43 META-PATTERN ABSTRACTION already does this manually)
- **Rolling "lessons learned" summary**

## Human Memory Analogues

- **Tulving 1972**: episodic (specific events) vs semantic (general knowledge)
- **Squire**: declarative (facts) vs procedural (skills)
- **Atkinson-Shiffrin** three-stage (sensory → short-term → long-term)
- **Baddeley** working memory (phonological loop + visuospatial sketchpad + central executive + episodic buffer)
- **Hippocampus + cortex consolidation** (Squire-Alvarez 1995) — sleep-mediated transfer = `dreaming-retro` skill running weekly

## Forgetting + Memory Management

- **LRU eviction** — least-recently-used
- **TTL** (time-to-live) policies
- **Confidence decay** — old facts marked uncertain over time
- **Manual delete + retract** — for outdated/contradicted facts

## How Forbidden Files Genius Memory Should Evolve

### Immediate (this week)
1. **Fix MEMORY.md size warning** (44KB > 24KB) — move details into `memory/<topic>.md` files, keep index to one-liners
2. **Wire `dreaming-retro`** to weekly Sunday 03:00 cron via the `schedule` skill
3. **Standardize four claude-flow namespaces**: `patterns` / `episodes` / `decisions` / `feedback`

### Short-term (2 weeks)
4. **Auto-categorizer wrapper** around `memory_store` (Mem0 pattern)
5. **Contradiction detection** on every write (Mem0)
6. **Hybrid retrieval** (vector + BM25 RRF fusion)
7. **`hooks_post-task` reflection trigger** — post every render, agent reflects + writes feedback file

### Medium (1 month)
8. **Bi-temporal metadata** (`valid_from` / `valid_to` per fact — Zep pattern)
9. **Confidence decay daemon**
10. **Hierarchical summarization** (LlamaIndex TreeIndex)
11. **Per-render decision log** in `decisions/` namespace

### Long (1 quarter)
12. **Graphiti migration** if memory mass > 10K entries
13. **Cross-encoder rerank** (bge-reranker-v2-m3 ONNX)
14. **Memory dashboard** for audit + visualization

## Sources (34)

Packer et al MemGPT 2023 arXiv:2310.08560; Mem0 docs 2024; Zep arXiv:2501.13956; Graphiti repo; Malkov HNSW 2016; Cormack RRF 2009; Carbonell MMR 1998; Tulving 1972 Episodic and Semantic Memory; Squire-Alvarez 1995; Atkinson-Shiffrin 1968; Baddeley 1986; LangChain Memory docs; LlamaIndex docs; Anthropic Contextual Retrieval 2024; Pinecone docs; Weaviate docs; Chroma docs; Milvus docs; LanceDB docs; OpenAI text-embedding-3 launch; BGE paper; Cohere embed-v3; HNSW paper Malkov-Yashunin 2018; FAISS Johnson 2017; Bjork directed forgetting; Stickgold 2005 sleep consolidation.

## PAIRS WITH

ai-autonomy-research-canon, expert-learning-science-canon, genius, dreaming-retro, self-improving-production-pipeline, skill-abstraction-canon, multi-agent-systems-canon.
