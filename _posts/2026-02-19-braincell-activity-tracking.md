---
layout: post
title: "Building a Job Tracker with BrainCell Activity Memory"
subtitle: "How persistent activity tracking powers smarter job search"
date: 2026-02-19
background: '/img/bg-braincell.jpg'
tags: [braincell, activity-tracking, job-search, assignmenthunter, development]
---

## The Problem: Tying It All Together

I've been building across multiple domains—**job search intelligence** (AssignmentHunter), **cloud infrastructure architecture** (ITL ControlPlane), and **semantic knowledge systems** (BrainCell). The challenge? Seeing how they fit together and remembering what actually works across all three.

Looking for my next role, I realized these aren't separate projects—they're interconnected pillars:
- **AssignmentHunter**: Aggregates job opportunities intelligently
- **ITL ControlPlane**: Manages multi-cloud infrastructure at scale
- **BrainCell** + **Activity Tracking**: Powers semantic search and decision memory

But without documentation, each decision vanishes. New scrapers duplicate logic from old ones. Architecture decisions get re-litigated. Strategic knowledge lives only in commits and my head.

BrainCell's activity tracker changed that. Instead of decisions scattered across multiple repos and commits, they're documented with rationale, tagged, and searchable across all three systems.

---

## A Week of Multi-System Development

Here's what BrainCell tracked as I consolidated three interconnected systems:

**AssignmentHunter (Job Search Platform):**
- Restructured documentation from 20 scattered files → 9 focused guides
- Created 13 comprehensive component summaries (API service, MCP server, Web UI, scrapers, filtering engine, database, BrainCell integration, Docker, Kubernetes, CLI)
- Finalized microservices architecture with shared job_hunter module
- Set up Kubernetes deployment with HPA auto-scaling for production

**ITL ControlPlane (Cloud Infrastructure):**
- Architected TOGAF 9.2-aligned multi-cloud platform
- Standardized ResourceProvider pattern with 5 concrete implementations (Core, IAM, Identity, Compute, Custom)
- Designed event-driven lifecycle hooks (Before/After Create/Update/Delete)
- Established governance: ADR process, ARB review, SDK contracts
- Documented multi-tenancy model (Tenant ↔ Keycloak Realm 1:1)

**BrainCell + Integration Layer:**
- Integrated Weaviate v4 semantic search for job intelligence
- Built two-layer job storage system (PostgreSQL persistence + Weaviate indexing)
- Documented filtering strategy: score jobs during scraping, not after
- Created 147-item activity memory across all three systems

**Total captured**: 147 distinct activities across 3 interconnected domains

---

## Where It Clicks: Systems Converging

Wednesday, something shifted. I was reviewing AssignmentHunter's intelligent filtering when I realized: *this pattern mirrors ITL ControlPlane's provider architecture.*

Both use event-driven lifecycle hooks:
- **AssignmentHunter**: Before scraping (prepare filters) → After scraping (deduplicate, store, index)
- **ControlPlane**: Before Create (validate scope) → After Create (trigger audit, send events)

Instead of rebuilding this pattern for Weaviate integration, I queried BrainCell: *"What's our event-driven pattern across systems?"*

Got back 12 related activities spanning three repos, with full rationale for each decision. Recognized the pattern immediately, applied it consistently.

**The realization**: These aren't separate projects. They're layers:
1. **Data Foundation** (AssignmentHunter): Scrapes raw job data, filters intelligently, stores persistently
2. **Knowledge Layer** (BrainCell): Indexes scraped data semantically, enables intelligent search
3. **Infrastructure Layer** (ControlPlane): Governs how all services deploy, communicate, and scale

Each layer has its own concerns, but they share:
- Async/event-driven patterns
- Resource lifecycle management
- Multi-tenancy isolation
- Intelligent filtering/scoring

**Without activity tracking**, I would've reinvented these patterns three times.
**With it**, I recognized them immediately and kept consistency across all three systems.

A potential employer sees: "You have 3 separate projects."
The reality: One coherent architecture with three specialized implementations.

---

## The Architecture Converges

The power multiplied Friday when I consolidated documentation across all three systems.

I asked BrainCell: *"What patterns do we use for resource lifecycle management?"*

Got back activities from three different repos:
- **AssignmentHunter**: Job lifecycle (scrape → filter → deduplicate → store → index)
- **ControlPlane**: Resource lifecycle (validate scope → create → emit events → persist)
- **BrainCell**: Knowledge lifecycle (ingest → embed → index → search)

Three different domains. Same pattern:
1. **Validate** (check constraints, prevent duplicates)
2. **Transform** (apply scoring/filtering/embedding)
3. **Persist** (store in primary database)
4. **Index** (make searchable/discoverable)
5. **Emit event** (notify downstream systems)

**The consistency**: If someone new joins the team (or I apply for a role and explain the architecture), they see: one coherent system thinking, applied across three domains.

**What made this visible**: Activity tracking with proper tagging. I could search "lifecycle" or "event-driven" and see implementations across all repos simultaneously. Without it, this consistency would've been accidental, not intentional.

This matters because:
- New features follow proven patterns (less reinventing)
- Code reviews are faster (familiar patterns everywhere)
- Debugging is easier (understand the pattern, understand the implementation)
- Team knowledge doesn't evaporate when someone leaves

---

## The Audit Trail: A Week Across Three Systems

Every activity is timestamped and categorized:

**Monday**: Documentation restructure
- "Consolidate 20 scattered docs → 9 focused guides (55% reduction)"
- "Delete DEPLOYMENT.md, MICROSERVICES.md, MIGRATION.md (outdated content)"
- Rationale: *Single source of truth reduces confusion, prevents conflicting guidance*

**Monday-Wednesday**: AssignmentHunter Architecture
- "Single unified package (src/job_hunter/) with 3 service entry points"
- "13 component summaries: API, MCP, Web, Database, BrainCell, Filtering, Docker, Kubernetes, Kind, Scrapers, CLI"
- Rationale: *Shared module eliminates duplication, service separation maintains concerns*

**Wednesday-Thursday**: ControlPlane Governance
- "TOGAF 9.2 alignment: Phase A (Vision) STRONG, Phases B-D designed"
- "ResourceProvider pattern with 5 providers: Core, IAM, Identity, Compute, Custom"
- "Event-driven lifecycle hooks (Before/After) with RabbitMQ coordination"
- Rationale: *Governance + patterns + event coordination enable safe multi-cloud scaling*

**Thursday-Friday**: Integration & Convergence
- "Weaviate v4 semantic search integration stable"
- "Job storage pipeline: PostgreSQL persistence + Weaviate indexing"
- "Identified consistent lifecycle pattern across all three systems"
- Rationale: *Consistency across surfaces increases team velocity, reduces cognitive load*

**By Friday**: 147 documented activities capturing the evolution and coherence of three interconnected systems.

---

## What Changed: From Scattered Work to Coherent Architecture

**Before this week:**
- 3 separate repos, 20 documentation files, decisions scattered across commits
- Built features independently; didn't see patterns across systems
- New features started from scratch because no memory of previous decisions
- Architectural consistency was accidental, not intentional
- Knowledge lived in my head, not in searchable, shareable form

**This week's work:**
- Consolidated documentation (20 → 9 files)
- Created 13 component summaries for AssignmentHunter
- Documented 60+ ControlPlane architecture decisions
- Identified consistent patterns across all three systems
- Built 147-item activity memory with semantic tags
- All decisions documented with rationale and timestamps

**The result by Friday:**
- **Visibility**: Can see interconnections between AssignmentHunter (data aggregation), BrainCell (semantic indexing), and ControlPlane (infrastructure governance)
- **Consistency**: Three separate systems following same architectural patterns (lifecycle management, event-driven coordination, intelligent filtering)
- **Searchability**: Query "resource lifecycle" and see implementations across all three repos
- **Explainability**: When explaining architecture to a potential team, have full rationale for every decision

**Why this matters for my next assignment:**
When interviewing, I don't say "I built a job search platform, a cloud infrastructure system, and a vector search integration."

I say: *"I built a coherent multi-layer architecture: data aggregation layer (AssignmentHunter) powering a semantic knowledge layer (BrainCell) governed by infrastructure-as-code (ControlPlane). All three systems share consistent patterns for resource lifecycle management, event-driven coordination, and intelligent filtering. Every architectural decision is documented with rationale and can be traced to specific dates and commits."*

That tells a story of intentional design, not scattered projects.

---

## The Work: What We Actually Built

This week across AssignmentHunter, ControlPlane, and BrainCell:

| System | Work Done | Impact |
|--------|-----------|--------|
| **AssignmentHunter** | 13 component summaries, doc restructure (20→9), microservices finalized | Production-ready job aggregation platform |
| **ControlPlane** | TOGAF architecture, 5 resource providers, event-driven lifecycle | Enterprise multi-cloud infrastructure governance |
| **BrainCell** | Weaviate v4 integration, job storage pipeline, semantic indexing | Intelligent knowledge layer powering all systems |
| **Cross-System** | Identified consistent patterns, 147 documented activities, governance standards | Coherent architecture with repeatable patterns |

**Total**: 147 documented activities showing three systems converging around shared architectural principles.

---

## Why This Matters for Infrastructure & Scale

Building intelligent systems requires constant, interconnected decisions:

**Data Aggregation Layer (AssignmentHunter):**
- Job filtering: Which signals matter most? How do we prevent low-quality matches?
- Deduplication: Same job on 3 boards—consolidate or keep separate?
- Ranking: Balance demand signals (high pay) vs fit signals (perfect role match)?

**Infrastructure Layer (ControlPlane):**
- Provider isolation: Each provider owns single responsibility, coordinates via events
- Multi-tenancy: Tenant ↔ Realm mapping, scope-based access control
- Scaling: Development (1 replica) vs production (3 replicas, HPA 2-10)

**Knowledge Layer (BrainCell):**
- Semantic indexing: Which fields matter for embedding?
- Search quality: How do we rank semantic results vs keyword search?
- Performance: Batch operations (100-500 jobs) vs single-job indexing?

**Without activity tracking**: These decisions drift. Different implementations per layer. Re-solve problems months later because no record of previous decisions. Team knowledge evaporates.

**With activity tracking**: One source of truth showing how all three layers coordinate around consistent patterns. That's not just convenience—that's architectural integrity at scale.

This matters especially when scaling: new team members understand not just *what* systems do, but *why decisions were made*, enabling confident extensions and optimizations.

---

## The Unexpected Benefit

The best part? **Writing down the activity made me think differently.**

When I documented "Why filter jobs during scraping instead of after ingestion?", I had to articulate the tradeoffs: database load vs flexibility, speed vs accuracy. It made me either more confident in the choice or realize I needed to reconsider.

The act of recording wasn't security insurance; it was a design tool.

---

## What's Next: Packaging This for the Next Chapter

Now that architecture and decisions are tracked, I can:
- **Articulate the vision**: Three-layer system (data aggregation → semantic indexing → infrastructure governance) with consistent patterns
- **Explain the reasoning**: Every architectural decision has documented rationale, timing, and alternatives considered
- **Demonstrate scale readiness**: Kubernetes deployment with HPA, multi-tenancy support, event-driven coordination
- **Show team readiness**: Clear documentation, patterns, standards—can onboard new teammates confidently

**For my next assignment:**
The real value isn't "I built 3 systems." It's: *"I built 3 interconnected systems with intentional architecture, consistent patterns across all layers, and complete decision history. Every architectural choice is documented with rationale. New features follow established patterns. The system can scale to team and organizational size because the thinking is explicitly captured, not implicit."*

That demonstrates:
- Architectural maturity (thinking beyond the code)
- Systems thinking (seeing how layers interconnect)
- Team awareness (documenting not just what, but why)
- Long-term thinking (building for future maintainability, not just immediate delivery)

When evaluating my next role, I want: **a team that values this kind of intentional, documented architecture.** Organizations that let you build scattered feature islands don't scale. Teams that invest in shared architectural understanding do.

---

*Are you tracking how your different systems and interests fit together? Or does each project live in isolation?*
