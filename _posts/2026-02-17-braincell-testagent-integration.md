---
layout: post
title: "BrainCell: Persistent Memory System for AI Agents"
date: 2026-02-17
updated: 2026-02-17
categories: [ai-agents, memory-systems, architecture]
tags: [braincell, semantic-memory, itl-controlplane, agents, knowledge-management, microservices]
description: "BrainCell is a semantic memory system for AI agents. Store decisions, code patterns, and architectural knowledge. Search by meaning. Agents improve over time."
---



# BrainCell: Persistent Memory for AI Agents — Notes from an ITL Control Plane Architect

I built BrainCell because I kept running into the same problem across projects: agents and automation were stateless, teams repeatedly reinvented solutions, and important design context disappeared with time. This post is a practical account of how I approached that problem within the ITL Control Plane.

I developed BrainCell as a pragmatic, governed memory layer that fits into our control plane: it captures decisions, surfaces patterns, and makes architectural knowledge usable by both humans and agents. The goal was never academic—this is about reducing friction, improving onboarding, and making better platform decisions faster.

---



## Why this bothered me

In practice I saw three persistent issues:

- No durable record of architectural decisions or code patterns
- Little cross-team knowledge sharing — useful patterns stayed tribal
- Lost context when people moved on

That meant recurring work, inconsistent implementations, and slower platform evolution. Fixing that was a practical priority for the control plane: we need a single, governed source of truth for decisions and patterns.

---



## How I approached the solution

I designed BrainCell around a few practical principles:

- Keep decisions durable and auditable: everything is versioned with metadata
- Make retrieval semantic: teams must find relevant knowledge even when phrasing differs
- Enforce governance: role-based access and audit hooks integrate with platform IAM
- Keep it extensible: independent services that align with the provider pattern

What we store: design decisions (rationale + impact), typed code snippets, and architecture notes with compliance context. Integration points include the API, Dashboard, and MCP protocol so agents and workflows can use the same knowledge surface.

---



## How it's structured — a quick tour

I kept the architecture simple and aligned with the control plane:

- API: contract-first REST endpoints for storing and querying memory (port 9504)
- Dashboard: a review and discovery UI for humans (port 9507)
- MCP: agent-facing protocol surface so automation can call the same knowledge base (port 9506)

Under the hood: PostgreSQL for authoritative, auditable records; Weaviate for semantic search; Redis for caching and responsiveness. Governance is baked in: role-based access, audit trails, and hooks for platform compliance.

---



## Implementation: how I organized the code and builds

I separated each service and gave it a focused Dockerfile so teams can build and run only what they need. This keeps images small, reduces blast radius for changes, and follows the provider pattern we use across the control plane.

```
src/api/Dockerfile         # REST API
src/web/Dockerfile         # Dashboard
mcp/Dockerfile             # MCP server
```

---



## Technology Stack: Chosen for Governance, Extensibility, and Performance

| Layer         | Technology                        |
|---------------|-----------------------------------|
| Web Framework | FastAPI 0.127.0 (API & Dashboard) |
| Database      | PostgreSQL 15                     |
| Vector Search | Weaviate 1.27.0                   |
| Caching       | Redis 7                           |
| Templates     | Jinja2 + Bootstrap 5.3.2          |
| Orchestration | Docker Compose                    |
| Protocol      | Model Context Protocol (MCP)      |

All technology choices are aligned with ITL Control Plane standards for type safety, async performance, and operational clarity.


---


## Knowledge Assets: What Gets Governed and Shared

**Design Decisions:**
- Use pytest with fixtures for isolated tests (governed by platform testing standards)
- SDK requires 85%+ coverage (enforced by CI/CD and ARB)
- Handler Mixin Pattern for code reuse (documented for provider teams)
- Coverage strategy for providers (shared as a best practice)

**Architecture Notes:**
- Testing framework design (reference for new provider teams)
- SDK test suite structure (template for extensibility)
- Best practices and standards (living documentation)

**Sample Queries:**
- "How do we test resource providers?"
- "Show me multi-tenant testing patterns"
- "What's our code coverage requirement?"

---


## Technology Summary: Platform Integration

- **FastAPI**: REST API for storage and queries, aligned with platform API standards
- **PostgreSQL**: Authoritative database for decisions and notes, with audit and compliance
- **Weaviate**: Vector search for semantic matching, enabling semantic governance
- **Docker Compose**: Local orchestration (6 containers), production via Kubernetes/Helm

---


## Trying it locally (quick start)

If you want to try BrainCell locally I usually do this:

```bash
cd ITL.BrainCell
docker-compose up -d
```

From Python, a minimal example looks like:

```python
client = BrainCellClient("http://localhost:9504")
client.store_decision("Use pytest fixtures", "Better test isolation")
results = client.search("Testing patterns")
```

This is how I validate new provider onboarding and confirm the semantic search behaves for real queries.

---


## Results: What changed for teams

In practice I saw immediate wins:

- Teams stopped re-implementing the same integration patterns
- Onboarding time dropped because people could search for decisions and examples
- Governance improved — decisions are auditable and discoverable

Those outcomes are exactly why I keep BrainCell part of our control plane stack.

---


## Semantic Search: Governance and Platform Enablement

**Keyword search:**
> "lifecycle test" — Finds documents with exact words

**Semantic search (Weaviate):**
> "lifecycle test" — Finds related concepts (e.g., resource state transitions, setup/teardown, creation patterns)

Semantic search enables retrieval by meaning, not just keywords—critical for platform governance, onboarding, and compliance audits.

---


## Key Features: Architected for Governance and Extensibility

- Persistent memory across sessions and platform upgrades
- Shared, governed knowledge base for all agents and provider teams
- Natural language and semantic search for onboarding and compliance
- Traceable, auditable decision history for platform governance

---


## What I learned along the way

- Semantic storage matters: teams find the right knowledge even when they use different terms
- A hybrid approach (PostgreSQL + Weaviate) gives both structure and meaning
- Capturing the "why" is as important as the "what" — context drives better reuse
- Small, practical wins in developer velocity and compliance compound over time

---


## Vectors & Weaviate: Technical Overview for Platform Architects

**Vectors** are numerical representations of meaning. Similar meanings yield similar vectors, enabling semantic governance and onboarding.

Example:
```
Text:    "How to test async code?"
Vector:  [0.23, -0.45, 0.89, ...]  # 384 dimensions
```

**Semantic search** uses these vectors to find related content, not just exact matches.

**Embedding Model:**
- `sentence-transformers/all-MiniLM-L6-v2` (384-dim vectors, local inference)

**Weaviate** is a vector database optimized for semantic search. It uses HNSW (Hierarchical Navigable Small World) for efficient nearest-neighbor queries.

| Traditional DB | Vector DB (Weaviate) |
|---|---|
| Text, numbers, dates | Vectors (meaning) |
| Keyword search | Semantic similarity |
| SQL queries | Vector similarity queries |

**Workflow:**
1. Agent or provider team stores a decision (text + vector)
2. Later, platform users or governance processes query by meaning; Weaviate returns ranked results

**Benefits:**
- Fast, scalable semantic search for onboarding, compliance, and platform improvement
- Finds relevant knowledge even with different phrasing or evolving terminology

---



## Final thoughts

I designed BrainCell to be pragmatic: useful day-to-day for engineers, and rigorous enough for platform governance. If you work on provider onboarding, documentation, or automation, think of BrainCell as the shared memory that reduces rework and raises platform quality. I'm continuing to refine it; if you try it, I'd appreciate hearing what patterns you store and how it changes your workflows.
