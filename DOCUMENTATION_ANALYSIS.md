# Edgehog Documentation Analysis & Improvement Plan

Edgehog is a sophisticated IoT device management platform built on Astarte.
Below is a thorough analysis of documentation files identifying significant structural issues, critical gaps, and opportunities for improvement that impact onboarding, adoption, and long-term success.

---

## 1. Documentation Map

### Current Structure

```
doc/
├── pages/
│   ├── user/ (9 files) - End-user documentation
│   │   ├── intro_user.md - 16-line intro with broken link
│   │   ├── core_concepts.md - Excellent: Hardware types, System Models, Selectors
│   │   ├── hardware_types.md, system_models.md - Entity docs
│   │   ├── devices.md, devices_and_runtime.md - Device management
│   │   ├── groups.md, channels.md - Grouping concepts
│   │   ├── batch_operations.md - 30-line stub ("planned for future")
│   │   └── attribute_value_sources.md - 1-line stub
│   │
│   ├── ota_updates/ (5 files) - OTA-specific docs
│   │   ├── ota_update_concepts.md - Good concept coverage
│   │   ├── base_images.md, base_image_collections.md - Entity docs
│   │   ├── update_campaigns.md - UI walkthrough
│   │   └── ota_updates.md - Manual OTA procedures
│   │
│   ├── containers/ (6 files) - Container management
│   │   ├── core_concepts.md - Excellent: Images, Volumes, Networks, Releases
│   │   ├── applications_management.md - Container creation UI guide
│   │   ├── volume_management.md, network_management.md - CRUD guides
│   │   ├── image_credentials_management.md - Auth guide
│   │   └── deployment_campaigns.md - Rollout mechanics
│   │
│   ├── architecture/ (1 file) - System architecture
│   │   └── overview.md - High-level diagram (57 lines)
│   │
│   ├── admin/ (1 file) - Operations
│   │   └── deploying_with_kubernetes.md - Comprehensive K8s guide (938 lines!)
│   │
│   ├── integrating/ (2 files) - Integration docs
│   │   ├── interacting_with_edgehog.md - High-level overview
│   │   └── astarte_interfaces.md - EMPTY (1 line, generated)
│   │
│   ├── tutorials/ (1 file) - Getting started
│   │   └── edgehog_in_5_minutes.md - Docker-based quickstart
│   │
│   └── devguide/ (2 files) - Developer docs
│       ├── edgehog_just_in_time.md - just-based workflow
│       └── typos_and_formatting.md - Style guide
│
├── images/ - 50+ UI screenshots
└── mix.exs - Doc build configuration
```

### Documentation by Audience

| Audience | Files Available | Coverage Quality |
|----------|----------------|------------------|
| **Platform Operators** | 1 (K8s deploy) | Comprehensive but overwhelming |
| **End Users** | 15+ | Good for containers/OTA, poor for basics |
| **Device Engineers** | 0 direct | Interfaces in separate repo, no integration guide |
| **Backend Developers** | 2 (backend README, just guide) | Minimal |
| **Frontend Developers** | 1 (34 lines) | Inadequate |
| **Contributors** | 1 (CONTRIBUTING.md: 23 lines) | Insufficient |

---

## 2. Gap Analysis

### Critical Missing Documents

1. **GraphQL API Reference** - Referenced but not generated
   - Files mention `tenant-graphql-api/` but it doesn't exist
   - 144KB schema.graphql exists but no human-readable docs
   - No query/mutation examples for common operations

2. **Astarte Interface Documentation** - Empty placeholder
   - `astarte_interfaces.md` is 1 line (empty)
   - Interface JSONs exist but no explanation
   - No device-side integration guide

3. **Device Runtime Integration Guide** - Nonexistent
   - No guide for firmware engineers
   - No "How to make your device work with Edgehog"
   - Interface mapping not explained

4. **Authentication & Authorization Guide** - Missing
   - JWT generation mentioned but not explained
   - Admin API vs Tenant API distinction unclear
   - No token lifecycle management

5. **Troubleshooting & Debugging** - Missing
   - No "My device isn't showing up" guide
   - No log interpretation
   - No common failure modes

### Misleading or Outdated Documents

| Document | Issue |
|----------|-------|
| `intro_user.md` | Broken link to `tenant-graphql-api/` |
| `batch_operations.md` | Entirely "planned for future release" |
| `attribute_value_sources.md` | 1-line placeholder |
| `ota_update_concepts.md` | "Optional mechanism planned for future" |
| `interacting_with_edgehog.md` | Missing sections, references non-existent API docs |

### Under-Documented Concepts

1. **Multi-tenancy** - Mentioned but not explained
   - How tenants map to Astarte realms
   - Tenant isolation guarantees
   - Multi-tenant vs single-tenant deployment

2. **Data Flow** - High-level only
   - No sequence diagrams for device registration
   - No explanation of trigger flow
   - No data lifecycle documentation

3. **Security Model** - Implicit only
   - No threat model
   - No security best practices
   - No compliance guidance (GDPR mentioned once)

---

## 3. Reader Journeys

### Journey A: "I want to onboard my first device"

**Target Audience**: IoT Developer, Day 1 Experience

**Current Path**:
1. README.md → Links to docs.edgehog.io
2. Edgehog in 5 minutes → Docker setup
3. ...device doesn't show up
4. Interacting with Edgehog → "Publish SystemInfo"
5. ...how? No device SDK guide
6. Check Astarte interfaces → JSON files, no examples
7. **STUCK**: No device-side code examples

**Knowledge Gaps**:
- No "Your First Device" tutorial
- No device runtime setup guide
- No interface implementation examples
- No "Hello World" device code

**Assumed Knowledge**:
- Astarte concepts (realm, interface, aggregation)
- MQTT pub/sub
- Device credential generation
- JSON interface format

### Journey B: "I want to deploy this platform in production"

**Target Audience**: DevOps Engineer, Platform Operator

**Current Path**:
1. README.md → Kubernetes deployment link
2. Deploying with Kubernetes (938 lines!)
3. **OVERWHELMED**: Secrets, DNS, ingress, certs, S3, DB...
4. Try to follow but miss critical steps
5. Tenant creation via Admin API → token generation unclear
6. **STUCK**: No troubleshooting when things fail

**Pain Points**:
- 938-line deployment guide is unmanageable
- No "minimum viable production" path
- No infrastructure-as-code examples (Terraform/Pulumi)
- No monitoring/observability setup
- No backup/restore procedures
- No upgrade procedures

**Missing**:
- Helm charts or Kustomize configs
- Health checks and readiness probes
- Log aggregation setup
- Metric collection (Prometheus/Grafana)
- Disaster recovery procedures

### Journey C: "I want to extend the platform or contribute code"

**Target Audience**: Open Source Contributor, Backend Developer

**Current Path**:
1. CONTRIBUTING.md → 23 lines, no code standards
2. Backend README → Setup, build, test
3. Edgehog Just in Time → just-based workflow
4. Try to understand architecture → 57-line overview
5. Look at code → Ash framework, complex domains
6. **STUCK**: No developer onboarding for Ash/Elixir

**Knowledge Locked in Code**:
- Ash resource patterns
- Multi-tenancy implementation
- GraphQL resolver patterns
- Astarte integration details
- Testing patterns (mocks, factories)

**Missing**:
- Architecture Decision Records (ADRs)
- Code contribution guidelines
- Domain model documentation
- API design principles
- Testing strategy documentation

---

## 4. Improvement Plan

### Structural Changes

#### A. Reorganize Documentation Hierarchy

**Current groups in mix.exs**:
```elixir
"User Guide": ~r"/user/",
"OTA Updates": ~r"/ota_updates/",
"Containers management": ~r"/containers/",
Architecture: ~r"/architecture/",
"Admin Guide": ~r"/admin/",
"Integrating with Edgehog": ~r"/integrating/",
Tutorials: ~r"/tutorials/",
"Developer guide": ~r"/devguide/"
```

**Proposed Structure**:
```elixir
"Getting Started": [
  "pages/getting-started/quickstart.md",      # NEW: 15-min Docker setup
  "pages/getting-started/first-device.md",     # NEW: Your first connected device
  "pages/getting-started/concepts.md"          # MOVE: core concepts intro
],

"User Guide": [
  "pages/user/intro.md",                       # RENAME: intro_user
  "pages/user/devices.md",
  "pages/user/hardware-types.md",              # RENAME: consistency
  "pages/user/system-models.md",
  "pages/user/groups.md",
  "pages/user/channels.md",
  "pages/user/batch-operations.md"             # MERGE: or delete if not implemented
],

"Device Management": [
  "pages/devices/registration.md",             # NEW: How devices appear
  "pages/devices/telemetry.md",                # NEW: Data flow explanation
  "pages/devices/containers.md",               # MOVE from containers/
  "pages/devices/ota-updates.md"               # MOVE from ota_updates/
],

"Platform Operations": [
  "pages/ops/requirements.md",                 # NEW: Prerequisites
  "pages/ops/kubernetes-deployment.md",        # SPLIT: from 938-line monster
  "pages/ops/configuration.md",                # NEW: Environment variables
  "pages/ops/monitoring.md",                   # NEW: Observability
  "pages/ops/security.md",                     # NEW: Security hardening
  "pages/ops/upgrading.md",                    # NEW: Version upgrades
  "pages/ops/troubleshooting.md"               # NEW: Common issues
],

"Integrations": [
  "pages/integrations/astarte-setup.md",       # NEW: Astarte integration
  "pages/integrations/device-sdks.md",         # NEW: Runtime guides
  "pages/integrations/graphql-api.md",         # NEW: Generated API docs
  "pages/integrations/admin-api.md",           # NEW: Admin REST API
  "pages/integrations/interfaces.md"           # FIX: Generate content
],

"Developer Guide": [
  "pages/dev/contributing.md",                 # EXPAND: from 23 lines
  "pages/dev/architecture.md",                 # EXPAND: from 57 lines
  "pages/dev/backend.md",                      # EXPAND: from 112 lines
  "pages/dev/frontend.md",                     # EXPAND: from 34 lines
  "pages/dev/testing.md",                      # NEW: Testing patterns
  "pages/dev/ash-framework.md"                 # NEW: Ash resource patterns
]
```

#### B. Create New Critical Documents

**High Priority (Week 1-2)**:

1. **`pages/getting-started/first-device.md`** (Priority: CRITICAL)
   - Prerequisites check
   - Device credential generation
   - Interface implementation walkthrough
   - Connection verification
   - "Hello World" telemetry example

2. **`pages/integrations/graphql-api.md`** (Priority: CRITICAL)
   - Auto-generated from schema.graphql
   - Common query examples
   - Authentication examples
   - Error handling

3. **`pages/ops/troubleshooting.md`** (Priority: HIGH)
   - Device not showing up
   - Authentication failures
   - Campaign failures
   - Container deployment issues
   - Log locations and interpretation

**Medium Priority (Month 1)**:

4. **`pages/ops/kubernetes-deployment.md`** (Refactor)
   - Split into: Planning → Prerequisites → Installation → Verification
   - Extract: secrets setup, ingress config, storage setup
   - Add: Infrastructure-as-code examples

5. **`pages/dev/contributing.md`** (Expand)
   - Code of Conduct reference
   - Development workflow
   - Pull request template
   - Commit message conventions
   - Testing requirements

6. **`pages/integrations/device-sdks.md`**
   - Edgehog Device Runtime (Rust)
   - Edgehog ESP32 (C)
   - Edgehog Zephyr (C)
   - Custom SDK development

**Lower Priority (Month 2-3)**:

7. **`pages/ops/monitoring.md`**
   - Prometheus metrics
   - Grafana dashboards
   - Alerting rules
   - Health check endpoints

8. **`pages/dev/architecture-decisions/`** (ADR folder)
   - Why Ash Framework
   - Why Astarte
   - Multi-tenancy design
   - Container orchestration approach

#### C. Fix Broken/Misleading Content

| File | Action |
|------|--------|
| `intro_user.md` | Fix broken `tenant-graphql-api/` link |
| `astarte_interfaces.md` | Generate from interface JSONs or remove |
| `batch_operations.md` | Delete or note "not yet implemented" |
| `attribute_value_sources.md` | Delete or expand |
| `deploying_with_kubernetes.md` | Split into 4-5 focused documents |

---

## 5. Quick Wins vs Long-Term Investments

### Quick Wins (Days to 1 Week)

| Task | Effort | Impact |
|------|--------|--------|
| **Fix broken links** | 30 min | High - removes frustration |
| **Generate GraphQL API docs** | 2 hours | Critical - API is main interface |
| **Create "First Device" tutorial** | 1 day | Critical - unblocks adoption |
| **Split K8s deployment guide** | 4 hours | High - improves usability |
| **Add troubleshooting section** | 4 hours | High - reduces support burden |
| **Expand CONTRIBUTING.md** | 2 hours | Medium - improves contributions |
| **Document common GraphQL queries** | 4 hours | High - enables API usage |

### Medium-Term (1-4 Weeks)

| Task | Effort | Impact |
|------|--------|--------|
| **Generate Astarte interface docs** | 2 days | High - device integration |
| **Create device SDK guides** | 3 days | Critical - device adoption |
| **Write security hardening guide** | 2 days | High - production readiness |
| **Create monitoring setup guide** | 3 days | Medium - operations |
| **Document Ash resource patterns** | 2 days | Medium - contributor onboarding |
| **Create architecture diagrams** | 2 days | Medium - system understanding |

### Long-Term Investments (1-3 Months)

| Task | Effort | Impact |
|------|--------|--------|
| **Interactive API explorer** | 2 weeks | High - developer experience |
| **Video tutorials** | 2 weeks | High - visual learners |
| **Infrastructure-as-code examples** | 1 week | Medium - production deployments |
| **ADR repository** | Ongoing | Medium - architectural transparency |
| **Automated doc testing** | 1 week | Medium - prevent doc drift |
| **Multi-language translations** | Ongoing | High - global adoption |

---

## Specific Recommendations

### Immediate Actions (This Week)

1. **Fix the empty `astarte_interfaces.md`** - Either generate content or remove the file
2. **Create `pages/getting-started/first-device.md`** - Tutorial using existing device runtime
3. **Add GraphQL examples** - At minimum, document 10 common operations
4. **Split `deploying_with_kubernetes.md`** - Create table of contents, extract sections

### Documentation Conventions to Adopt

1. **Every concept doc gets a "When to use this" section**
2. **Every procedure gets prerequisites and expected outcomes**
3. **Every code example must be copy-pasteable and tested**
4. **Broken features marked with ⚠️ or removed from docs**
5. **Links validated in CI/CD pipeline**

### Key Metrics to Track

- Time to first device connection (target: < 30 minutes)
- Deployment success rate from docs (target: > 90%)
- API documentation coverage (target: 100% of public API)
- User-reported doc issues (track in GitHub)

---

## Conclusion

Edgehog has excellent technical documentation for its container and OTA features, but suffers from critical gaps in onboarding, API documentation, and operational guides. The documentation currently serves experienced users well but creates significant friction for newcomers.

**The highest-impact improvements** are:
1. **First Device Tutorial** - Unblocks adoption
2. **GraphQL API Documentation** - Enables integration
3. **Troubleshooting Guide** - Reduces support burden
4. **Refactored Deployment Guide** - Improves production readiness

With focused effort on these areas, Edgehog can transform from a platform requiring significant tribal knowledge to one that enables self-service adoption at all skill levels.

---

*Analysis completed: 2026-02-06*  
*Next step: Prioritize and implement improvements incrementally*
