---
layout: post
title: "ITL Policy Builder: Closing the Gap Between Security Intent and Runtime Reality"
date: 2026-04-18 09:00:00 +0200
categories: [governance, platform-engineering]
tags: [policy-as-code, azure, kubernetes, kyverno, cis, pqc, iso27001, nis2, itl-controlplane, cli, python, iac, blueprint, governance]
description: "The ITL Policy Builder is a Python SDK and CLI that generates, validates, and deploys governance policies across Azure and Kubernetes. Includes a declarative blueprint format for governance topology as code."
author: "Niels Weistra"
excerpt: "Every platform I've worked on had the same problem. Security teams write requirements. Engineers deploy infrastructure. And nobody writes the policies that connect them."
---

I've been quiet here for a while. That changes now. Lot of things have been building up and they deserve proper writeups. Starting with something I see go wrong on almost every platform I work on: **the governance gap**.

---

## Here's What I Keep Seeing

Security team produces a 40-page hardening document. CIS benchmark lands in Confluence. ISO 27001 audit is coming up. NIS2 is now law and someone needs to prove measures are in place. PQC transition plan sits in a shared drive. Somewhere a CISO signs off on a compliance document.

Meanwhile, engineers deploy infrastructure.

And the policies that were supposed to enforce all those requirements? Either never written, or configured manually, inconsistently, and drifting the moment someone touches a subscription.

This isn't a people problem. It's structural.

- Azure Policy is ARM JSON. Kubernetes enforcement is Kyverno YAML. Nobody wants to write both, let alone keep them in sync.
- CIS benchmarks, BIO controls, ISO 27001 requirements, NIS2 obligations, PQC requirements — they're documents, not deployable artifacts.
- Getting from a policy definition to an active assignment across management groups and subscriptions requires stitching together multiple tools.
- Policy gets treated as configuration, not code. No versioning, no review, no pipeline.

The ITL Policy Builder is what I built to close that gap.

---

## What It Does

A Python SDK and CLI (`itl-policy`) that covers the full lifecycle:

1. **Generate** governance policies from curated templates — Azure ARM format, Kyverno YAML, or both
2. **Validate** before anything touches a live environment
3. **Deploy** directly to Azure (policy definitions and initiative assignments), Kubernetes clusters, or the ITL Control Plane API
4. **Publish** bundles to a registry — ITL catalog, OCI artifact store, or a Git repo

The entire pipeline can run from a single command or be wired into CI/CD.

---

## The Templates: Standards You Actually Need

The most immediately useful part is the template library. Instead of writing policy JSON from scratch, you generate from a named standard.

Full transparency: the templates are still being worked on. The foundation is there — the structure, the generation pipeline, the CIS sections. But some templates still need coverage work and I keep adding controls as I go. What's there is usable. What's missing, I'm filling in.

### CIS Azure Benchmark — 60 policies across 16 control sections

The [CIS Microsoft Azure Foundations Benchmark](https://www.cisecurity.org/benchmark/azure) is the standard hardening baseline for Azure. The builder ships all 60 policies, organised into control sections: Identity and Access, Security Center, Storage, Database, Logging and Monitoring, Networking, Virtual Machines, App Service, Key Vault, and more.

```bash
# Generate all CIS Azure policies as an ARM initiative
itl-policy generate --template cis-azure --style azure --format json --output cis-azure.json

# Inspect what's in a section first
itl-policy explain --template cis-azure --section AKS
itl-policy explain --template cis-azure --severity High
```

### BIO (Baseline Informatiebeveiliging Overheid) — 17 policies

For Dutch government and public sector organisations, BIO compliance is mandatory. These policies map BIO controls to Azure Policy effects. Previously this was something every project had to figure out from scratch.

### PQC Transition — 16 policies

Post Quantum Cryptography is not a future concern anymore. NIST finalised the first PQC standards in 2024. The builder ships 16 policies that enforce algorithm controls, key size minimums, and certificate lifecycle requirements across both Azure and Kubernetes workloads.

```bash
itl-policy generate --template pqc-transition --style azure --format json --output pqc.json
itl-policy generate --template pqc-transition --style kyverno --output pqc-kyverno.yaml
```

### Talos Security — Kyverno baseline for hardened Kubernetes

For clusters running [Talos Linux](https://www.talos.dev/) (our hardened OS layer), there's a Kyverno policy bundle that enforces the security posture at the workload level: image restrictions, privilege escalation blocks, network policy requirements, and more.

---

## Nine Commands, Full Lifecycle

```
itl-policy list        # Browse available templates by category
itl-policy generate    # Generate policies (Azure ARM or Kyverno YAML)
itl-policy validate    # Validate before deploying
itl-policy deploy      # Deploy to Azure, Kubernetes, or ITL Control Plane
itl-policy publish     # Publish a bundle to ITL catalog, OCI registry, or Git
itl-policy inventory   # Audit what's currently assigned, across subscriptions
itl-policy describe    # Fetch live details for a specific Azure governance resource
itl-policy explain     # Human-readable breakdown of any template or Azure concept
itl-policy init        # Initialise local configuration
```

The `explain` command is worth calling out specifically. It's not just documentation — it's a usable reference that surfaces the reasoning behind each policy:

```bash
itl-policy explain --about management-group
itl-policy explain --about policy-effect
itl-policy explain --template cis-azure --section "CIS-3" --severity High
```

---

## What It Actually Fixes

Let me be concrete. Before this tool, a typical engagement looked like this:

| Problem | Before | With Policy Builder |
|---------|--------|---------------------|
| CIS Azure baseline | Manual policy definitions, usually incomplete | `itl-policy generate --template cis-azure` + deploy |
| Rollout across subscriptions | Per subscription manual ARM deploys | `--assignment-scope /providers/Microsoft.Management/managementGroups/...` |
| Kyverno and Azure parity | Separate tools, separate files, separate reviews | Single template, two format targets |
| Policy drift detection | None, or bespoke scripts | `itl-policy inventory` + diff against Git state |
| PQC readiness | Spreadsheet or not started | 16 deployable policies with severity tagging |
| GitOps for policy | Not applicable | `itl-policy publish --registry git` |

The biggest shift is moving from policy as a manual activity to policy as a pipeline step. Generate, validate, publish, deploy — on every merge to main. Drift becomes visible immediately.

---

## The Pipeline It Enables

Each CLI command is a stage. Compose them:

```yaml
# .github/workflows/policy-engine.yml
steps:
  - run: itl-policy generate --template cis-azure --style azure --output bundle.json
  - run: itl-policy validate -f bundle.json --target azure
  - run: itl-policy publish -f bundle.json --name cis-azure --version ${{ github.sha }}
  - run: itl-policy deploy -f bundle.json --target azure
               --subscription-id $AZURE_SUBSCRIPTION_ID
               --assignment-scope $SCOPE
               --action enforce
```

Add a scheduled drift detector that calls `inventory` and compares against the published Git state, and you have a governance layer that keeps itself honest. Wire in an ITL BrainCell agent that can reason about violations and generate corrective policies, and the loop closes completely.

That's the direction I'm building toward. The CLI is the foundation.

---

## Governance as a Blueprint

One thing I keep running into: you can have great policies, but the topology of *where* they're attached is just as important and just as easy to get wrong. Which initiative is assigned at tenant root? Which subscriptions get the CIS baseline? Which management groups are in enforce mode vs audit?

Right now that's all manual, scattered across ARM deployments, portal clicks, and the memory of whoever set it up.

The direction I'm taking this is a declarative **governance blueprint** — a single file that describes your entire governance topology: the management group tree, subscriptions attached to each node, and which policy sets are deployed at which scope in which mode.

```yaml
# governance-blueprint.yaml
blueprint:
  name: itl-platform-governance
  version: 1.0.0

  management_groups:
    - id: mg-itl-root
      display_name: ITL Root
      children:
        - id: mg-platform
          display_name: Platform
          children:
            - id: mg-platform-identity
              display_name: Platform Identity
            - id: mg-platform-connectivity
              display_name: Platform Connectivity
        - id: mg-landing-zones
          display_name: Landing Zones
          children:
            - id: mg-lz-production
              display_name: Landing Zones Production
            - id: mg-lz-nonproduction
              display_name: Landing Zones Non-Production
        - id: mg-sandbox
          display_name: Sandbox

  subscriptions:
    - id: sub-platform-001
      display_name: Platform Core
      management_group: mg-platform
    - id: sub-prod-001
      display_name: Production Workloads
      management_group: mg-lz-production
    - id: sub-dev-001
      display_name: Development
      management_group: mg-lz-nonproduction

  policy_assignments:
    - initiative: cis-azure
      scope: mg-itl-root
      mode: audit
      description: CIS Azure baseline applied at root for full visibility
    - initiative: cis-azure
      scope: mg-lz-production
      mode: enforce
      description: Enforce CIS on production landing zones
    - initiative: pqc-transition
      scope: mg-platform
      mode: audit
    - initiative: bio-baseline
      scope: mg-itl-root
      mode: audit
    - initiative: talos-kyverno
      scope: cluster://prod-aks-01
      mode: enforce
```

Then a single command renders that into the actual ARM assignments and Kyverno manifests and applies it:

```bash
itl-policy blueprint apply -f governance-blueprint.yaml --dry-run
itl-policy blueprint apply -f governance-blueprint.yaml
```

And the reverse: take whatever is currently deployed across an environment and generate the blueprint from it:

```bash
itl-policy blueprint export --subscription-id <id> --output governance-blueprint.yaml
```

This gives you a source of truth that lives in Git. You review it, version it, run it through a pipeline. The actual state in Azure or Kubernetes becomes a consequence of the file, not the other way around.

It's also the foundation the GUI will be built on. The dashboard doesn't manage raw ARM assignments — it manages the blueprint. Visual editor on one side, YAML on the other, deployed state reconciled underneath.

---

## What's Next

A few things I'm actively working on.

**Better template coverage.** The structure is solid. The generation pipeline works. But the template library needs more breadth — more CIS sections fleshed out, BIO controls mapped more completely, ISO 27001 controls translated to Azure Policy, NIS2 technical requirements turned into enforceable policies, PQC policies that cover edge cases I keep finding in the field.

**Governance blueprints.** As described above — a declarative file format for the full governance topology. Management groups, subscriptions, policy assignments, modes. One file, one apply. Export from existing environments. Version it.

**A GUI for policy assignment management.** The CLI and blueprints are the right tool for pipelines. But for a security officer who wants to see what's enforced where, or a platform engineer who needs to move a subscription to a different management group and understand what policy implications that has — a visual layer matters. The dashboard will sit on top of the blueprint model, not raw ARM. Visual editor, YAML underneath, reconciled state on the right.

That dashboard will be integrated with the ITL Control Plane, so everything runs through the same governance model: resource hierarchy, tenant isolation, audit trail.

**RBAC on policy management.** Right now you either have access or you don't. That's not good enough. The plan is role-based access tied into the ITL IAM provider — so a security officer can view and approve policy bundles, a platform engineer can deploy, and a developer has read-only visibility into what's enforced on their workloads. Scoped to subscription or management group level.

None of this is theoretical. It's on the board.

---

## Get Started

```bash
pip install itl-policy-builder

# Generate and inspect your first bundle
itl-policy generate --template cis-azure --style azure --output cis-azure.json
itl-policy explain --template cis-azure --section AKS

# Deploy to Azure in audit mode first
itl-policy deploy -f cis-azure.json --target azure \
  --subscription-id "<your-sub-id>" \
  --assignment-scope "/subscriptions/<your-sub-id>" \
  --action audit
```

Source and docs: [github.com/ITlusions/ITL.ControlPanel.PolicyBuilder](https://github.com/ITlusions/ITL.ControlPanel.PolicyBuilder)

---

More coming. Next up: building out the blueprint format properly, the drift detection loop, and how BrainCell fits in as the decision memory layer for the policy engine.
