---
layout: post
title: "Ship It & Track It: Webhooks for Process Traceability"
date: 2025-10-11 10:00:00 +0200
categories: [DevOps, Automation]
tags: [webhooks, traceability, monitoring, ci-cd, teams, notifications]
excerpt: "Turn your deployment pipeline into a traceable audit trail with smart webhook notifications that land right where your team works."
description: "Learn how to implement webhooks for complete process traceability in your DevOps pipeline, from build to production with Microsoft Teams integration."
image: "/assets/vscode-development-screenshot.jpg"
author: "Niels Weistra"
---

<img src="/assets/vscode-development-screenshot.jpg" alt="Webhook Process Traceability" style="width: 60%; height: auto; display: block; margin: 0 auto;">
*Real development environment showing webhook implementation and infrastructure monitoring*

Your deployments shouldn't disappear into the void. When code ships, services restart, or infrastructure changes, your team needs **complete visibility** right where they're already collaborating—and you need an audit trail that survives compliance reviews.

In our stack, every critical process event becomes a traceable record in Microsoft Teams: deployment status, version bumps, rollback triggers, and infrastructure changes. It's not just notifications—it's a living operations log that connects every action to its outcome.

## Why webhook-driven traceability beats "check the logs later"

* **Real-time process visibility:** See exactly what's happening as it happens, with context your team actually needs
* **Audit-ready trails:** Every deployment, rollback, and infrastructure change gets logged with timestamps, actors, and links
* **Faster incident response:** Failed processes post immediately with commit info, error context, and direct links to troubleshooting
* **Compliance made simple:** Your Teams channel becomes your deployment ledger—searchable, exportable, and timestamped

## The traceability pattern (implementation in 5 minutes)

Your webhook strategy should capture **three critical process moments**: start, success, and failure. Each webhook payload should answer: *who did what, when, and with what result?*

### 1. Set up your audit channel

In Microsoft Teams: **Apps → Incoming Webhook → Configure**
- Name it something clear: "Production Deployments" or "Infrastructure Changes"
- Copy the webhook URL
- Store as `TEAMS_WEBHOOK_URL` in your repository secrets

### 2. Implement the traceability pattern

Here's our production pattern that captures every deployment event:

```yaml
name: Deploy with Full Traceability

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.version.outputs.version }}
    steps:
      - uses: actions/checkout@v4
      - name: Get version
        id: version
        run: echo "version=$(date +%Y%m%d)-${GITHUB_SHA::8}" >> $GITHUB_OUTPUT
      
      - name: Deployment Started
        run: |
          curl -X POST -H 'Content-Type: application/json' \
            -d '{
              "@type": "MessageCard",
              "themeColor": "0078D4",
              "title": "Deployment Started",
              "sections": [{
                "facts": [
                  {"name": "Service", "value": "${{ github.repository }}"},
                  {"name": "Version", "value": "${{ steps.version.outputs.version }}"},
                  {"name": "Triggered by", "value": "${{ github.actor }}"},
                  {"name": "Branch", "value": "${{ github.ref_name }}"}
                ]
              }]
            }' "${{ secrets.TEAMS_WEBHOOK_URL }}"

  deploy:
    needs: [build]
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to production
        run: |
          # Your deployment logic here
          echo "Deploying version ${{ needs.build.outputs.version }}"
          
  notify-result:
    needs: [build, deploy]
    if: ${{ always() }}
    runs-on: ubuntu-latest
    env:
      STATUS: ${{ contains(join(needs.*.result, ','), 'failure') && 'FAILED' || 'SUCCESS' }}
      COLOR: ${{ contains(join(needs.*.result, ','), 'failure') && 'D00000' || '2EB886' }}
    steps:
      - name: Deployment Result
        run: |
          curl -X POST -H 'Content-Type: application/json' \
            -d '{
              "@type": "MessageCard",
              "themeColor": "${{ env.COLOR }}",
              "title": "Deployment ${{ env.STATUS }}",
              "sections": [{
                "facts": [
                  {"name": "Service", "value": "${{ github.repository }}"},
                  {"name": "Version", "value": "${{ needs.build.outputs.version }}"},
                  {"name": "Status", "value": "${{ env.STATUS }}"},
                  {"name": "Duration", "value": "${{ github.workflow_duration || 'Unknown' }}"},
                  {"name": "Commit", "value": "${{ github.sha }}"}
                ],
                "text": "Deployment completed by **${{ github.actor }}** at $(date -u +\"%Y-%m-%d %H:%M:%S UTC\")"
              }],
              "potentialAction": [{
                "@type": "OpenUri",
                "name": "View Workflow",
                "targets": [{"os": "default", "uri": "https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }}"}]
              }, {
                "@type": "OpenUri", 
                "name": "View Commit",
                "targets": [{"os": "default", "uri": "https://github.com/${{ github.repository }}/commit/${{ github.sha }}"}]
              }]
            }' "${{ secrets.TEAMS_WEBHOOK_URL }}"
```

## What you get: A living audit trail

Every webhook creates a **searchable record** in Teams with:
- **Exact timestamps** for compliance and SLA tracking
- **Direct links** to workflow runs, commits, and documentation
- **Actor accountability** showing who triggered each change
- **Version correlation** connecting deployments to specific code changes
- **Failure context** with immediate links to troubleshooting resources

## Security & compliance best practices

* **Rotate webhook URLs quarterly** and keep them in repository secrets only
* **Use dedicated channels** for different environments (prod, staging, dev)
* **Include traceability IDs** in your webhook payloads for correlation across systems
* **Archive channels annually** for long-term audit compliance
* **Test your webhooks** in staging before production rollouts

## Advanced: Infrastructure-as-Code traceability

For Terraform or Kubernetes deployments, include infrastructure change context:

```bash
# In your Terraform pipeline
curl -X POST -H 'Content-Type: application/json' \
  -d "{
    \"@type\": \"MessageCard\",
    \"title\": \"Infrastructure Change Applied\",
    \"sections\": [{
      \"facts\": [
        {\"name\": \"Environment\", \"value\": \"${TF_WORKSPACE}\"},
        {\"name\": \"Resources Changed\", \"value\": \"${TF_PLAN_CHANGES}\"},
        {\"name\": \"Terraform Version\", \"value\": \"${TF_VERSION}\"},
        {\"name\": \"Plan ID\", \"value\": \"${TF_PLAN_ID}\"}
      ]
    }]
  }" "$TEAMS_WEBHOOK_URL"
```

---

Your deployment process should tell a story. Make sure it's a story your team can read, search, and learn from.