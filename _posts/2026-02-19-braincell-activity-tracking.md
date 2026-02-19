---
layout: post
title: "Building a Job Tracker with BrainCell Activity Memory"
subtitle: "How persistent activity tracking powers smarter job search"
date: 2026-02-19
background: '/img/bg-braincell.jpg'
tags: [braincell, activity-tracking, job-search, assignmenthunter, development]
---

## The Problem: Everything's Separate (Until It Isn't)

Here's what I've learned over the past week: I didn't build three separate projects. I built one coherent architecture with three specialized implementations, and I almost forgot how they connect.

I've been working across three domains—**job search intelligence** (AssignmentHunter), **cloud infrastructure architecture** (ITL ControlPlane), and **semantic knowledge systems** (BrainCell). Each one is self-contained, has its own repo, its own CLI, its own deployment story. On the surface, they look independent.

But they're not.

When I started looking for my next assignment, something shifted. I realized: a potential employer sees "you built 3 projects." The reality? One coherent multi-layer system:
- **Data aggregation layer** (AssignmentHunter): Scrapes, filters, persists job opportunities
- **Knowledge layer** (BrainCell): Indexes, embeds, makes data semantically searchable
- **Infrastructure layer** (ITL ControlPlane): Governs how all services deploy, scale, and communicate

But here's the problem I hit: without documentation, the connections die.

New scraper? You reinvent filtering logic because you forgot the pattern from three months ago.
New provider? You don't see that ControlPlane uses the same lifecycle hooks as AssignmentHunter.
Explaining your architecture? You sound like you've been building scattered features, not a coherent system.

BrainCell's activity tracker solved this. Instead of decisions dissolved into commits, they're documented with rationale, tagged, and instantly searchable across all three systems. Suddenly, the connections become visible.

---

## A Week of Connecting the Pieces

Let me walk you through what happened when I spent a week intentionally documenting how these three systems fit together. BrainCell tracked everything:

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

## The Moment It Clicked: Patterns Across Different Domains

Wednesday morning, I was knee-deep in AssignmentHunter's intelligent filtering logic. And then it hit me—**I've seen this pattern before**. Not in job scrapers. In ControlPlane's provider architecture.

Let me show you what I mean.

**AssignmentHunter's resource lifecycle:**
1. Before scraping: Prepare filters, validate job board connection
2. During scraping: Apply intelligent scoring (skills, salary, location, company reputation)
3. After scraping: Deduplicate across job boards, store in PostgreSQL, index in Weaviate
4. On error: Log, alert, continue with next batch

**ControlPlane's resource lifecycle:**
1. Before Create: Validate scope, check permissions, pre-audit
2. During Create: Create resource, apply resource-specific logic
3. After Create: Publish events, sync relationships, audit logging, metrics
4. On error: Cleanup, SIEM alerts, failure tracking

Same pattern. Different domains. Same lifecycle hooks pattern.

So I did what any developer would do—I queried BrainCell: *"What patterns do we use across all three systems?"*

Got back activities from three different repos, full with rationale and timestamps. Suddenly, I wasn't looking at three projects. I was looking at one architecture:

1. **Data Aggregation Layer** (AssignmentHunter): Raw data → filter → persist
2. **Knowledge Layer** (BrainCell): Persist → embed → index → search
3. **Infrastructure Layer** (ControlPlane): Deploy → govern → scale → audit

Each layer independent. Each following the same lifecycle patterns. Each event-driven, each auditable, each observable.

**This is the moment it mattered.**

It's not that I discovered the patterns were the same. It's that I could **articulate why**—see the rationale, understand the consistency, and explain it to someone else (like a hiring manager) without hand-waving. Activity memory made the connections tangible, not implicit.

"I built 3 projects" → "I built a coherent multi-layer architecture with consistent patterns across all three systems." That's a completely different story.

---

## The Architecture Converges

The power multiplied Thursday when I consolidated documentation across all three systems.

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

**Thursday**: Integration & Convergence
- "Weaviate v4 semantic search integration stable"
- "Job storage pipeline: PostgreSQL persistence + Weaviate indexing"
- "Identified consistent lifecycle pattern across all three systems"
- Rationale: *Consistency across surfaces increases team velocity, reduces cognitive load*

**By Thursday**: 147 documented activities capturing the evolution and coherence of three interconnected systems.

---

## What Actually Changed This Week

Here's the before-and-after:

**Monday morning:** 3 separate repos with 20 scattered documentation files. Decisions lost in commits. Each project built independently. No visible connection between how AssignmentHunter filters jobs, how ControlPlane routes requests, how BrainCell scores results. Knowledge lived in my head.

**Thursday afternoon:** 147 documented activities across all three systems. Every decision tagged, dated, and searchable. 13 component summaries showing how AssignmentHunter works. 60+ architecture decisions showing how ControlPlane works. Clear visibility into how all three systems share consistent patterns.

**The practical difference:**

| Before | After |
|--------|-------|
| "I built a job search system" | "I built an intelligent data aggregation layer" |
| "I built a cloud control plane" | "I built an infrastructure governance layer" |
| "I built vector search integration" | "I built a semantic knowledge layer" |
| No visible connection | One coherent architecture, three specialized implementations |

**The searchability difference:**
Before: "How did I handle lifecycle management in AssignmentHunter?" → Dig through code, reverse-engineer
After: Query BrainCell: "lifecycle management" → Get 12 activities across 3 repos, full rationale

**The explainability difference:**
When interviewing for my next role, I'm not saying: "I built 3 projects."

I'm saying: *"I built a three-layer architecture where data aggregation (AssignmentHunter) feeds into semantic indexing (BrainCell), both governed by infrastructure patterns (ControlPlane). All three systems share the same lifecycle patterns, event-driven coordination, and intelligent filtering approach. Every decision is documented with rationale, making the architecture reproducible and the thinking visible."*

See the difference? One story is "things I built." The other is "an intentional system I designed." 

Activity tracking with proper documentation makes the difference between scattered features and coherent architecture. And that matters when you're looking for a team that values architectural thinking.

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

## Why This Pattern Matters: The Hard Part of Scaling

Here's the uncomfortable truth: **most teams don't scale because their architecture doesn't scale. Their thinking doesn't scale.**

The hard decisions happen early:

**How do you filter jobs in AssignmentHunter?**
- Score during scraping or after? (Answer: During. Reduces DB churn, improves quality earlier)
- What signals matter? (Skills 40%, salary 25%, location 20%, company reputation 15%)
- How do you deduplicate across 9 job boards? (Store hash of core fields, check on ingest)

**How do you architect ControlPlane?**
- Tight coupling or event-driven coordination? (Answer: Events. Core Provider doesn't call IAM. They coordinate through message queue)
- One realm per tenant or multiple? (Answer: Multiple. Enables regional isolation, compliance flexibility, team autonomy)
- How do you prevent scope creep in a resource model? (Abstract base classes. SDK contracts. Everything flows through the same pipeline)

**How do you index in BrainCell?**
- Single job or batch? (Answer: Both. Batch for volume, single for real-time. Different performance characteristics, same API)
- What makes a job \"relevant\"? (Stop using heuristics. Use semantic embedding. Let the model decide)

These decisions aren't obvious. They're learned through iteration, mistakes, and hard-won experience. **Writing them down is how you avoid repeating them.**

Without activity tracking, here's what happens when a new person joins:
- They don't see the pattern
- They solve it differently
- The codebase becomes inconsistent
- Debugging gets harder
- Onboarding takes longer
- Knowledge leaks when they leave

**With activity tracking**:
New teammate: \"How should I handle filtering in this new scraper?\"
You: \"Query BrainCell for 'intelligent filtering'. See the pattern we established. Follow it.\"
Instead of rediscovering the pattern, they inherit it.

That's how teams scale. Not with bigger teams. With better thinking made visible.

---

## The Unexpected Benefit

The best part? **Writing down the activity made me think differently.**

When I documented "Why filter jobs during scraping instead of after ingestion?", I had to articulate the tradeoffs: database load vs flexibility, speed vs accuracy. It made me either more confident in the choice or realize I needed to reconsider.

The act of recording wasn't security insurance; it was a design tool.

---

## Why This Matters for Your Next Move

Here's what I learned: Activity tracking isn't just about remembering what you built. It's about proving that you *designed* what you built.

When you interview, you can say: "I built AssignmentHunter, ControlPlane, and BrainCell integration." That's a list.

Or you can say: "I architected a three-layer system: data aggregation (AssignmentHunter) → semantic indexing (BrainCell) → infrastructure governance (ControlPlane). All three systems use consistent lifecycle patterns, event-driven coordination, and intelligent filtering. I can show you every design decision, why I made it, when I made it, and what the alternatives were. New features follow established patterns because patterns are documented. Teams can onboard confidently because the thinking is explicit, not implicit."

That's a story about **architectural maturity**.

The difference matters because:
- **Scattered projects** say: "I can code"
- **Coherent architecture** says: "I can architect at scale"
- **Documented patterns** say: "I can lead teams"
- **Activity-tracked decisions** say: "I can teach why things work this way"

When you're looking for your next role, you want a team that values the last two. Organizations that celebrate shipping features die when they scale. Organizations that care about architectural thinking scale indefinitely.

Activity tracking makes that thinking visible.

---

**What's Next:**
The architecture is now documented. The patterns are visible. The connections between systems are explicit. This is what I'm bringing to my next assignment: not just code, but the thinking behind the code. Not just features, but the system that makes those features cohere.

That's what changes everything.

---

*Are you tracking how your systems fit together? Or are you building scattered features that just happen to evolve into architecture?*
