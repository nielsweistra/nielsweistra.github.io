---
layout: post
title: "ITL ControlPlane: Core & IAM Providers - Multi-Realm Architecture"
subtitle: "The patterns that make multi-tenant clouds work"
date: 2026-02-14
author: "ITL Team"
categories: ["Architecture", "Identity", "ControlPlane"]
tags: ["Core Provider", "IAM Provider", "Multi-Realm", "SDK", "Hooks", "Resource Management"]
image: "/assets/itl-multi-realm-architecture.png"
---

# ITL ControlPlane: Core & IAM Providers - Multi-Realm Architecture

In our [previous post](/blog/2026/02/09/itl-control-plane-alpha/), we introduced the ITL ControlPlane — the abstraction layer that comes *before* infrastructure. We talked about why patterns matter: hierarchical resource models, audit trails, governance at scale.

Today, we're going deeper. We're showing you the **first two resource providers** that make this abstraction real: **Core Provider** (resource management) and **IAM Provider** (identity & access management). These aren't just API endpoints. They're the foundation that everything else builds on.

At the heart of this architecture is an idea that solves a problem we've all faced: how do you manage identity when you have multiple environments, multiple regions, or multiple teams? The answer is multi-realm — one organization, multiple identity instances. Let's see how this works.

## The Architecture at a Glance

The control plane is built on proven, battle-tested technologies: Python and FastAPI for the API tier, PostgreSQL for relational data, Neo4j for resource relationships, RabbitMQ for event streaming, and Keycloak for identity. Docker Compose for local development, Kubernetes and Helm for production. Nothing exotic. Everything chosen for operational clarity and stability.

```
┌──────────────────────────────────────────────────────────────┐
│                    API Gateway (Router)                      │
│  POST /providers/ITL.Core/tenants                            │
│  POST /providers/ITL.Core/tenants/{tenant}/subscriptions     │
│  POST /subscriptions/{sub}/resourcegroups                    │
│  POST /providers/ITL.Core/tenants/{tenant}/realms            │
└──────────────────────┬───────────────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
┌───────▼──────────┐        ┌────────▼──────────┐
│  Core Provider   │        │  IAM Provider      │
│  (ITL.Core)      │        │  (ITL.IAM)         │
│                  │        │                    │
│ ├─ Tenants       │        │ ├─ Realms          │
│ ├─ Resource Grps │        │ ├─ Users           │
│ ├─ Subscriptions │        │ ├─ Roles           │
│ └─ Locations     │        │ ├─ Service Accts   │
│                  │        │ └─ Clients         │
└────────┬─────────┘        └────────┬───────────┘
         │                           │
         └───────────────┬───────────┘
                         ▼
        ┌─────────────────────────────┐
        │    PostgreSQL Database      │
        │  (SDK StorageEngine)        │
        │                             │
        │ ├─ tenants                  │
        │ ├─ realms (multi-per tenant)│
        │ ├─ subscriptions            │
        │ ├─ users                    │
        │ └─ audit trail              │
        └──────────────┬──────────────┘
                       │
                ┌──────▼──────┐
                │  Keycloak   │
                │  (Identity  │
                │   Service)  │
                └─────────────┘
```

## The Multi-Realm Model: Why It Matters

### Problem: Single Realm Limitations

Traditionally, organizations get one identity realm. This creates real problems: you can't isolate users by region, you can't separate production from staging safely, teams can't manage their own identity configuration, and testing changes means risking production systems. It's the centralized identity bottleneck that every enterprise knows too well.

But there are deeper issues. If you're using a cloud-based identity platform, you're at the mercy of its availability. What happens when that service goes down — do your systems fail in cascade? What about compliance? GDPR requires data residency in Europe, but your cloud provider's identity service might replicate globally. CCPA, LGPD, local regulations — each has different data handling requirements. And then there's the vendor lock-in problem: your identity is tied to one platform's API, schema, and operational model. If that platform becomes unavailable, deprecated, or you need to migrate, you're stuck.

### Solution: One Tenant, Multiple Realms

```
ACME Corporation (Tenant)
├─ Primary Realm: acme-corp
│  └─ Users: [alice@acme, bob@acme]
│  └─ Default for most operations
│
├─ Staging Realm: acme-staging
│  └─ Users: [dev-alice@acme, dev-bob@acme]
│  └─ For testing identity features
│
└─ EU Realm: acme-eu
   └─ Users: [pierre@acme-eu, maria@acme-eu]
   └─ EU data residency compliance

// All realms share the same tenant_id (ACME's organizational UUID)
// But each has independent configuration and user base
```

### Use Cases

| Scenario | Benefit |
|----------|---------|
| **Regional Isolation** | Comply with GDPR, CCPA, data residency laws — keep identity data where it needs to be |
| **Environment Separation** | Prod, staging, dev realms with different policies — test safely |
| **Team Autonomy** | Teams manage their own realm users/roles — no central bottleneck |
| **Safe Changes** | Test identity config changes without affecting others — reduce risk |
| **Disaster Recovery** | Realm failover without losing tenant identity — availability matters |
| **Platform Independence** | Multiple realms reduce lock-in to any single provider — run your own or switch providers |
| **Compliance Flexibility** | Different realms can have different data handling policies — meet regional regulations |

---

## Demo: Creating Tenants and Realms with the CLI

Let's walk through creating a multi-realm tenant using the **itlc** CLI:

### Step 1: Create a Tenant (Empty)

```bash
$ itlc tenant create \
  --name acme-corp \
  --display-name "ACME Corporation" \
  --region global

Tenant created successfully.
Response:
{
  "id": "/providers/ITL.Core/tenants/acme-corp",
  "name": "acme-corp",
  "displayName": "ACME Corporation",
  "tenantId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "state": "Active",
  "primaryRealmId": null,
  "createdAt": "2026-02-14T14:30:05Z"
}
```

### Step 2: Create Primary Realm under Tenant

```bash
$ itlc realm create \
  --tenant acme-corp \
  --name acme-corp \
  --display-name "ACME Production Realm"

Realm created successfully.
Response:
{
  "id": "/providers/ITL.Core/tenants/acme-corp/realms/acme-corp",
  "realmId": "123e4567-e89b-12d3-a456-426614174000",
  "tenantId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "name": "acme-corp",
  "status": "active",
  "isPrimary": true,
  "createdAt": "2026-02-14T14:30:10Z"
}
```

### Step 3: Create Secondary Realm (EU Compliance)

```bash
$ itlc realm create \
  --tenant acme-corp \
  --name acme-eu \
  --display-name "ACME EU Realm (GDPR)"

Secondary realm created.
Response:
{
  "id": "/providers/ITL.Core/tenants/acme-corp/realms/acme-eu",
  "realmId": "223e4567-e89b-12d3-a456-426614174111",
  "tenantId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "name": "acme-eu",
  "status": "active",
  "isPrimary": false,
  "createdAt": "2026-02-14T14:30:15Z"
}
```

### Step 4: List All Realms for Tenant

```bash
$ itlc realm list --tenant acme-corp

Realms for ACME Corporation:
┌────────────┬──────────────┬─────────────────────────────────┬──────────┐
│ Name       │ Display Name │ Realm ID                        │ Primary  │
├────────────┼──────────────┼─────────────────────────────────┼──────────┤
| acme-corp  │ ACME Prod    │ 123e4567-e89b-12d3-a456-...    │  Primary |
| acme-eu    │ ACME EU      │ 223e4567-e89b-12d3-a456-...    │    No    |
└────────────┴──────────────┴─────────────────────────────────┴──────────┘

Total: 2 realms
```

### Step 5: Create User in Specific Realm

```bash
$ itlc user create \
  --tenant acme-corp \
  --realm acme-corp \
  --username alice@acme.com \
  --email alice@acme.com \
  --first-name Alice \
  --last-name Engineer

User created in realm acme-corp.
Response:
{
  "id": "/providers/ITL.IAM/realms/acme-corp/users/alice@acme.com",
  "username": "alice@acme.com",
  "email": "alice@acme.com",
  "realmId": "123e4567-e89b-12d3-a456-426614174000",
  "status": "active",
  "createdAt": "2026-02-14T14:30:20Z"
}
```

### Step 6: Create User in EU Realm (Different Config)

```bash
$ itlc user create \
  --tenant acme-corp \
  --realm acme-eu \
  --username pierre@acme-eu.fr \
  --email pierre@acme-eu.fr \
  --first-name Pierre

User created in realm acme-eu.
Response:
{
  "id": "/providers/ITL.IAM/realms/acme-eu/users/pierre@acme-eu.fr",
  "username": "pierre@acme-eu.fr",
  "email": "pierre@acme-eu.fr",
  "realmId": "223e4567-e89b-12d3-a456-426614174111",
  "status": "active",
  "createdAt": "2026-02-14T14:30:25Z"
}
```

---

## SDK Architecture: Contracts and Implementations

Building a cloud control plane requires **clear contracts**. You don't want every provider reinventing the wheel, handling errors differently, or implementing storage in incompatible ways. The ITL SDK solves this with abstract base classes — contracts that say "every provider must implement these methods with these signatures." Python's type system makes this ironclad.

The SDK is the single source of truth. The API gateway doesn't know about Azure or Proxmox or any cloud-specific implementation. It knows the SDK contract. Providers implement that contract. Databases, cache layers, message queues all use the SDK models for serialization. One model, everywhere.

```
┌─────────────────────────────────────────────────────┐
│         ITL ControlPlane SDK                        │
│    (Contracts - Python abstract base classes)       │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ├─ ResourceProvider (ABC)                         │
│  │  ├─ create(), read(), delete(), list() abstract │
│  │  └─ All providers implement this contract       │
│  │                                                  │
│  ├─ StorageEngine (ABC)                            │
│  │  └─ Async ORM with SQLAlchemy 2.0               │
│  │                                                  │
│  └─ Resource Models                                │
│     ├─ TenantModel, RealmModel, UserModel          │
│     ├─ SpecModels (TenantSpec, RealmSpec, etc)     │
│     └─ Full type hints + Pydantic validation       │
│                                                     │
└────────────────────┬────────────────────────────────┘
                     │
    ┌────────────────┼────────────────┐
    │                │                │
┌───▼────────┐  ┌───▼──────────┐  ┌─▼────────────┐
│Core Provider   │IAM Provider  │ │Compute Provider
│ResourceProvider│ResourceProvider│ResourceProvider
│(Implements)    │(Implements)  │ │(Implements)
└────────────┘  └──────────────┘  └────────────┘
```

### Key SDK Components

#### 1. Resource Provider Contract (All Providers Implement)

```python
class ResourceProvider(ABC):
    """Base contract all providers implement — Core, IAM, Compute, Storage, etc."""
    
    # Hook names for lifecycle extensibility
    HOOK_BEFORE_CREATE = "before_create"
    HOOK_AFTER_CREATE = "after_create"
    HOOK_BEFORE_DELETE = "before_delete"
    HOOK_AFTER_DELETE = "after_delete"
    HOOK_ON_ERROR = "on_error"
    
    @abstractmethod
    async def create(self, spec: ResourceSpec, context: ProviderContext) -> Resource:
        """Create a resource from specification.
        
        For Core Provider: Create tenant, subscription, resource group
        For IAM Provider: Create realm, user, role
        For Compute Provider: Create VM, disk, network
        
        Lifecycle:
            - Hook: before_create(spec, context)
            - Provider creates resource
            - Hook: after_create(resource, context)
            - Hook: on_error(spec, context, error) if operation fails
        """
        pass
    
    @abstractmethod
    async def delete(self, resource_id: str, context: ProviderContext) -> None:
        """Delete a resource by ID.
        
        Lifecycle:
            - Hook: before_delete(resource_id, context)
            - Provider deletes resource
            - Hook: after_delete(resource_id, context)
            - Hook: on_error(resource_id, context, error) if operation fails
        """
        pass
    
    @abstractmethod
    async def list(self, context: ProviderContext) -> List[Resource]:
        """List resources in tenant context."""
        pass
```

Every provider implements the same contract. The resource types differ (tenants vs users vs VMs), but the operational interface is identical. This allows the API gateway to route requests to any provider without provider-specific logic.

#### 2. Storage Engine Pattern

```python
class StorageEngine(ABC):
    """Async ORM for all providers - type-safe database access."""
    
    async def session(self) -> AsyncSession:
        """Get database session."""
        pass
    
    def tenants(self, session) -> TenantRepository:
        """Access tenant repository."""
        pass
    
    def realms(self, session) -> RealmRepository:
        """Access realm repository."""
        pass
    
    def users(self, session) -> UserRepository:
        """Access user repository."""
        pass
```

---

## Hooks System: Extensibility Points

A platform that doesn't let you extend it becomes a cage. The SDK provides **lifecycle hooks** at key points where you can inject custom logic. Want to validate realm names match your organization standard? Hook it. Need to sync provisioned resources to an external system for tracking? Hook it. Got a security requirement where certain operations need approval? Hook it.

Hooks are called at natural extension points — before creation (validation, enrichment), after creation (events, synchronization), before deletion (cascade cleanup), after deletion (audit), on error (recovery, cleanup). They're async-first, so they don't block the provider's main flow.

More importantly, hooks are how you add **operational visibility**: audit trails (who did what, when, with what result), metrics (latency, success rates, resource counts), and structured logs (debugging, compliance, forensics).

```
Resource Lifecycle with Hooks:

Create Request
    │
    ▼
┌─────────────────────────────┐
│ Hook: before_create()       │  ← Validate, enrich, pre-audit
└──────────┬──────────────────┘
           │
           ▼
    Provider.create()
           │
           ▼
┌─────────────────────────────┐
│ Hook: after_create()        │  ← Publish events, sync, audit, metrics
└──────────┬──────────────────┘
           │
           ▼
    Return Resource
```

Think of hooks as observation points. Every resource operation flows through them. That means every operation can be:

- **Audited**: Log who requested it, what changed, who authorized it, what the result was
- **Metered**: Track operation latency, success/failure rates, resource counts, quota usage
- **Logged**: Structured logs for compliance, debugging, forensics

### Hook Examples

```python
# In your provider implementation:

class CoreProvider(ResourceProvider):
    def __init__(self):
        self.hooks = HooksManager()
        
        # Register custom hooks for audits, metrics, logs
        self.hooks.register('before_create_realm', self._validate_realm_name)
        self.hooks.register('after_create_realm', self._audit_creation)
        self.hooks.register('after_create_realm', self._record_metrics)
        self.hooks.register('on_error', self._log_error_context)
    
    async def create(self, spec, context):
        start_time = time.time()
        
        try:
            # Call before hook (validation)
            await self.hooks.execute('before_create_realm', spec)
            
            # Create resource
            realm = await self._create_realm(spec)
            
            # Call after hooks (audit, metrics, events)
            await self.hooks.execute('after_create_realm', realm, context)
            
            return realm
        except Exception as e:
            # Call error hook for logging
            await self.hooks.execute('on_error', spec, context, e)
            raise
    
    async def _validate_realm_name(self, spec):
        """Validate input before creation."""
        if not spec.name.startswith('org-'):
            raise ValidationError("Realm must start with 'org-'")
    
    async def _audit_creation(self, realm, context):
        """Record audit trail — who, what, when, why."""
        audit_entry = {
            "timestamp": datetime.utcnow(),
            "operation": "realm.created",
            "user_id": context.user_id,
            "tenant_id": context.tenant_id,
            "resource_id": realm.id,
            "resource_name": realm.name,
            "changes": {"name": realm.name, "status": realm.status},
            "status": "success"
        }
        await self.postgres_db.audit_log.insert(audit_entry)
    
    async def _record_metrics(self, realm, context):
        """Track operational metrics for monitoring."""
        duration_ms = (time.time() - self.operation_start) * 1000
        await self.metrics.record({
            "operation": "realm.create",
            "duration_ms": duration_ms,
            "status": "success",
            "tenant_id": context.tenant_id,
            "resource_type": "realm"
        })
        # Emit to Prometheus/Grafana for dashboards
        self.prometheus_counter.labels(
            operation="create",
            resource="realm",
            status="success"
        ).inc()
    
    async def _log_error_context(self, spec, context, error):
        """Structured logging for debugging and compliance."""
        self.logger.error(
            "operation_failed",
            operation="realm.create",
            user_id=context.user_id,
            tenant_id=context.tenant_id,
            spec_name=spec.name,
            error_type=type(error).__name__,
            error_message=str(error),
            trace_id=context.correlation_id,
            exc_info=True  # Include full stack trace
        )
        # Also send to SIEM for security monitoring
        await self.siem_client.log_event({
            "severity": "warning",
            "event_type": "resource_operation_failed",
            "user": context.user_id,
            "resource": spec.name,
            "error": str(error)
        })
```

**Key insight**: Every resource operation is an observation point. Hooks let you observe:

- **Audits** (`_audit_creation`): Record in audit log who did it, what changed, when, why. Compliance requirement for most regulated industries.
- **Metrics** (`_record_metrics`): Track operational health — creation latency, success rates, resource counts. Feed to Prometheus/Grafana for dashboards and alerting.
- **Logs** (`_log_error_context`): Structured logs for debugging and forensics. Send to centralized logging (ELK, Splunk) and SIEMs for security monitoring.

This is how you turn a control plane into an observable system.

### Available Hooks

| Hook | When | Use Case |
|------|------|----------|
| `before_create` | Before creating resource | Validation, enrichment, pre-audit |
| `after_create` | After successful creation | Event publishing, sync, audit logging, metrics recording |
| `before_delete` | Before deleting resource | Cascade cleanup, verification, pre-audit |
| `after_delete` | After successful deletion | Audit logging (deletion trail), notifications, metrics |
| `on_error` | When operation fails | Error logging, SIEM alerts, metrics, failure tracking |

---

## Core Provider: Resource Management Foundation

Remember from the first post how we talked about organizational hierarchy? Tenants at the top, then subscriptions, resource groups — levels of organization that let you delegate responsibility and track resources at scale. The Core Provider implements this.

A tenant is an organization. Under each tenant, you create subscriptions — billing and organizational domains. Within each subscription, you create resource groups — logical collections of resources. These aren't just database records — they're governance scopes. You can attach policies at the subscription level, audit at the resource group level, set budgets per subscription.

But here's where ITL ControlPlane differs from Azure. In Azure, when you create a tenant, you get exactly one EntraID directory. It's a 1-to-1 relationship. Your tenant and your identity provider are locked together. You can't have multiple identity instances within the same organization — if you need separate identity realms, you need separate tenants.

In ITL ControlPlane, realms are Core Provider resources. They're part of the organizational hierarchy, not a separate service locked at the tenant level. This means a single tenant can have 1, 2, or N realms. Event-driven coordination between Core Provider and IAM Provider creates each realm in Keycloak, but from the organizational perspective, they all belong to the same tenant. The separation of concerns — organizational hierarchy (Core) from identity management (IAM) — makes this possible. No monolithic coupling. No 1-to-1 locks.

This is what separates "a cloud you built" from "a bunch of servers you manage". The abstraction layer.

### Core Resources

```bash
# Create tenant (top-level organizational boundary)
$ itlc tenant create --name acme-corp --display-name "ACME Corporation"

# Create subscription under tenant
$ itlc subscription create \
  --tenant acme-corp \
  --name prod \
  --display-name "Production"

# Create resource group under subscription
$ itlc resource-group create \
  --tenant acme-corp \
  --subscription prod \
  --name rg-app \
  --display-name "Application Resources"
```

---

## IAM Provider: Identity & Access Management

The IAM Provider manages identity lifecycle. It acts as the middleware between the control plane and Keycloak — abstracting away Keycloak's complexity while providing the control plane abstraction model to users.

The provider manages realms (identity instances), users (identities), roles (permissions), groups (team organization), clients (integrated applications), and service accounts (workload identities). When the Core Provider creates a tenant, IAM Provider automatically creates a realm. When you delete a tenant, the realm goes with it.

The real question is: why separate providers for resource management and identity? Because they have different scaling patterns, different operational concerns, and different deployment boundaries. The Core Provider might run on one cluster; the IAM Provider might run elsewhere to reduce blast radius. They communicate through events, not API calls.

### IAM Resources

```bash
# Create realm
$ itlc realm create --tenant acme-corp --name acme-corp

# Create user
$ itlc user create \
  --tenant acme-corp \
  --realm acme-corp \
  --username alice@acme.com

# Create role
$ itlc role create \
  --tenant acme-corp \
  --realm acme-corp \
  --name admin \
  --description "Administrator role"

# Assign role to user
$ itlc role assign \
  --user alice@acme.com \
  --role admin \
  --realm acme-corp
```

---

## API: REST Endpoints with Optional Tenant Parameter

All endpoints follow a **flexible tenant scoping pattern**:

### User Access (Implicit Tenant from Auth)

```bash
# User accessing their own tenant's resources
GET /providers/ITL.Compute/compute/vms
# → Returns only VMs for logged-in user's tenant

GET /providers/ITL.IAM/realms
# → Returns only realms for logged-in user's tenant
```

### Admin Access (Explicit Tenant Override)

```bash
# Admin accessing another tenant (requires admin role)
GET /providers/ITL.Compute/tenants/{tenant}/compute/vms
# → Returns VMs for specified tenant (if user is admin)

GET /providers/ITL.IAM/tenants/{tenant}/realms
# → Returns all realms for specified tenant (if user is admin)
```

---

## Data Model: Tenant ↔ Realm Relationship

Here's where things get important: understanding the difference between ARM paths (REST API identities) and GUIDs (database identities).

When you create a tenant named "acme-corp", it gets:
- An **ARM path** (REST API): `/providers/ITL.Core/tenants/acme-corp` — human-readable, hierarchical, used in URLs
- A **GUID** (database): `f47ac10b-58cc-4372-a567-0e02b2c3d479` — stable, unique, never changes across services

Foreign keys always use the GUID. This is critical. When IAM Provider creates a realm, it stores `tenant_id: f47ac10b-...` in the database, not the ARM path. This ensures consistency across services. The Core Provider, IAM Provider, and any future provider all refer to the same tenant by the same GUID.

**Database Schema:**

```
tenants table
├─ id: /providers/ITL.Core/tenants/acme-corp (ARM path - REST only)
├─ tenant_id: f47ac10b-58cc-4372-a567-0e02b2c3d479 (GUID - database FK)
├─ name: acme-corp
├─ primary_realm_id: 123e4567-... (FK to realms)
└─ state: Active

realms table
├─ id: /providers/ITL.Core/tenants/acme-corp/realms/acme-corp (ARM path)
├─ tenant_id: f47ac10b-58cc-4372-a567-0e02b2c3d479 (FK to tenants - GUID)
├─ realm_id: 123e4567-... (Keycloak GUID)
├─ name: acme-corp
├─ status: active
└─ enabled: true

users table
├─ id: /providers/ITL.IAM/realms/.../users/alice (ARM path)
├─ realm_id: 123e4567-... (FK to realms)
├─ keycloak_user_id: abc-def-ghi (Keycloak user GUID)
├─ username: alice@acme.com
├─ email: alice@acme.com
└─ created_by: bob@acme.com (Audit trail)
```

---

## Event-Driven Architecture

Providers shouldn't know about each other. Core Provider shouldn't call IAM Provider. That creates tight coupling, brittle systems, and cascading failures when one service is slow.

Instead, providers publish **events** to a message queue. These are facts: "tenant.created", "realm.created", "user.confirmed". Other providers subscribe to events they care about. This way, the system is loosely coupled — each provider is independent, but coordinated through events.

When you create a tenant, here's what happens:

1. Core Provider creates the tenant in PostgreSQL
2. Core Provider publishes: `"tenant.created"` event with tenant GUID
3. IAM Provider receives the event, automatically creates a default realm in Keycloak, stores it in PostgreSQL
4. IAM Provider publishes: `"realm.created"` event
5. Core Provider receives the event, updates the tenant's `primary_realm_id`
6. Neo4j gets synced, activity logs get written

Everything is eventual consistency. Everything is auditable. No tight coupling, no "call this provider to set up that resource" chains.

```
Core Provider creates Tenant
    │
    └─► Publishes: cluster.tenant.created
         {
           "tenant_id": "f47ac10b-...",
           "tenant_name": "acme-corp",
           "timestamp": "2026-02-14T14:30:05Z"
         }
         │
         ▼
    IAM Provider receives event
    ├─► Create default realm in Keycloak
    ├─► Store realm metadata in PostgreSQL
    └─► Publishes: realm.created
         {
           "tenant_id": "f47ac10b-...",
           "realm_id": "123e4567-...",
           "status": "active"
         }
         │
         ▼
    Core Provider receives realm.created
    ├─► Update tenant.primary_realm_id
    ├─► Sync to Neo4j GraphDB
    └─► Tenant fully provisioned ✓
```

---

## What's Next

This is the foundation. Core and IAM providers give you the abstraction layer and identity management that everything else depends on. 

The roadmap ahead is deep. Compute Provider for workloads (VMs, Kubernetes clusters with Talos), Storage Provider for persistence (block, object, file), Network Provider for connectivity (VNets, tunnels, DNS). The order we build them depends on what the infrastructure needs first. Maybe compute. Maybe storage and networking together to support multi-tier applications. Maybe something else entirely — the abstraction layer is flexible enough to support discovery as we go.

Each provider follows the same pattern: clear SDK contracts, event-driven coordination, eventual consistency. The architecture scales because the foundation is solid. Add providers, wire up events, let the system coordinate itself.

Then the ecosystem: Infrastructure as Code providers, multi-cloud bridging, GitOps workflows. The patterns work. The technology is proven. Pattern upon pattern, abstraction upon abstraction.

---

## Demo Stack

The stack is designed to run locally with Docker Compose. Spin it up, and you get the full control plane running on your machine: API gateway, core provider, IAM provider, PostgreSQL, Neo4j, message queue. Everything talks to each other.

```bash
# Start the stack
cd ITL.ControlPanel.Stack
docker-compose up -d

# Create your first tenant
itlc login
itlc tenant create --name my-org --display-name "My Organization"

# Create realms
itlc realm create --tenant my-org --name my-org
itlc realm create --tenant my-org --name staging

# Create users (once Keycloak integration is complete)
itlc user create --tenant my-org --realm my-org --username admin@myorg.com

# See what you've built
itlc realm list --tenant my-org
itlc resource list --tenant my-org
```

The CLI and API use the same SDK models, same validation, same error handling. Build once, use everywhere.

---

## Getting Started

The full codebase is still being prepared for public release. We're cleaning up code, writing documentation, and making sure the repos are production-ready. Currently available:

- [ITL.ControlPanel.SDK](https://github.com/itl-controlplane/itl-controlplane-sdk) — The contract layer with all resource models and provider interfaces

The Core Provider, IAM Provider, and API Gateway implementations are coming soon. Follow the project for updates when repositories become available.

This is what the abstraction layer looks like when you get it right. Not overwhelming complexity hidden behind magic, but straightforward patterns — tenants, realms, users, roles — that follow the same logic as the commercial clouds that inspired them. The difference is you can see exactly how it works and run it yourself.

The compute provider is next. Then networking, storage, and governance. The wolf is still learning to run, but the foundation is solid.
