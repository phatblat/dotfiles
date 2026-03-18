---
name: research-protocol
description: |-
  Conduct rigorous research with proper citations (DOI, arXiv, PMID) and source triangulation.
  MUST BE USED when user asks: "what is SOTA", "recent developments", "compare X vs Y",
  "is it true that", "research says", "latest papers on", "scientific evidence", "studies show",
  "state of the art", "literature review", "find papers", "academic research",
  "benchmark results", "who published", "when was X released", "current best",
  "what does the research say", "evidence for", "peer reviewed".
  Searches multiple sources, evaluates reliability, states confidence level.
  NOT for verifying API signatures (use anti-hallucination) or general web search (use WebSearch directly).
allowed-tools:
  - WebSearch
  - WebFetch
  - mcp__fetch__fetch
  - mcp__huggingface__get-paper-info
  - mcp__huggingface__get-daily-papers
  - mcp__huggingface__search-models
  - Read
---

# Research Protocol

## Research Workflow

```
1. SCOPE    → Define question precisely
2. SEARCH   → Multiple sources, cross-reference
3. EVALUATE → Assess source reliability
4. SYNTHESIZE → Combine findings coherently
5. CITE     → Provide proper attribution
6. ASSESS   → State confidence level
```

## Source Hierarchy

| Priority | Source Type | Reliability | Citation Format |
|----------|-------------|-------------|-----------------|
| 1 | Peer-reviewed papers | Highest | [Author et al., Year] arXiv:XXXX |
| 2 | Official documentation | High | Docs [Library] vX.X |
| 3 | Conference proceedings | High | [Conf Year] Paper Title |
| 4 | Established tech blogs | Medium-High | [Org] Blog (Date) |
| 5 | GitHub repos with citations | Medium | GitHub [repo] |
| 6 | Stack Overflow (verified) | Medium | SO [answer-id] |
| 7 | General web content | Low | Mention skepticism |

## Search Strategy

### For SOTA (State of the Art)

```
1. mcp__huggingface__get-daily-papers()  → Recent papers
2. WebSearch("[topic] SOTA 2024")
3. WebSearch("[topic] benchmark comparison")
4. mcp__huggingface__search-models(tags: "[task]")
```

### For Specific Papers

```
1. WebSearch("paper title arxiv")
2. mcp__huggingface__get-paper-info(arxiv_id: "XXXX.XXXXX")
```

### For Library/API Questions

```
1. mcp__context7__resolve-library-id() first
2. Then research protocol for context
```

## Citation Formats

### Academic Papers

```
[Author et al., Year] "Title" - arXiv:XXXX.XXXXX
[Author et al., Year] "Title" - DOI:10.XXXX/XXXXX
[Author et al., Year] "Title" - PMID:XXXXXXXX
```

### Documentation

```
According to [Library] v[X.X] documentation: ...
According to [Framework] docs (2024): ...
```

### Web Sources

```
According to [Source Name] (Date): ...
Per [Organization] blog (Month Year): ...
```

## Confidence Assessment

| Confidence | Criteria | Response Style |
|------------|----------|----------------|
| **HIGH** | 3+ concordant sources, peer-reviewed | State as established fact |
| **MEDIUM** | 1-2 reliable sources | Add "according to [source]" caveat |
| **LOW** | Conflicting sources | Present multiple views |
| **UNKNOWN** | No reliable sources | "I don't know" |

## Handling Conflicts

When sources disagree:

```markdown
## Divergent Viewpoints

**Position A** (Source 1, Source 2):
[Description]

**Position B** (Source 3):
[Description]

**Assessment**: [Which seems more credible and why]
```

## Output Format

```markdown
## Summary

[Main findings - 3-5 lines max]

## Details

[Expanded information with inline citations]

## Sources

1. [Citation 1 with link/DOI]
2. [Citation 2 with link/DOI]
3. ...

## Confidence Level: [HIGH/MEDIUM/LOW]

[1-2 sentence justification]

## Limitations

- [What couldn't be verified]
- [Potential biases in sources]
- [Recency concerns if applicable]
```

## Red Flags (Requires Extra Scrutiny)

- Single source only
- Source older than 2 years (for fast-moving fields)
- Preprint without peer review
- Corporate blog with potential bias
- No citations in the source itself
- Contradicts well-established knowledge

## Research Triggers

Automatically engage this protocol when user asks about:

- "What is the current SOTA for..."
- "Recent developments in..."
- "Compare X vs Y"
- "Is it true that..."
- "What does the research say about..."
- "Latest papers on..."
- Scientific claims without citation