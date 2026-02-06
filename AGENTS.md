<!---
  Copyright 2026 SECO Mind Srl

  SPDX-License-Identifier: Apache-2.0
-->

# AGENTS.md — Edgehog Developer Guide

A practical, opinionated guide for AI coding agents and human contributors working on Edgehog.

---

## 1. Project Overview

**Edgehog** is an open-source IoT device management platform. It provides fleet management, OTA updates, container orchestration, and remote access for embedded Linux devices.

### Core Responsibilities

- **Device Lifecycle Management**: Registration, monitoring, and decommissioning of IoT devices
- **Over-the-Air (OTA) Updates**: Campaign-based firmware and software rollouts
- **Container Management**: Deploy and manage Docker containers on edge devices
- **Remote Access**: WebSocket-based tunnels for terminal and port forwarding
- **Fleet Operations**: Device grouping, tagging, and batch operations

### High-Level Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Frontend  │────►│   Backend   │────►│   Astarte   │
│  React/TS   │GQL  │  Elixir/    │REST │  IoT Platform│
│             │     │  Phoenix    │     │  (MQTT)     │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                                          MQTT │
                                               ▼
                                        ┌─────────────┐
                                        │   Devices   │
                                        │  (IoT Fleet)│
                                        └─────────────┘
```

**Key Integration**: Edgehog is built on top of [Astarte](https://docs.astarte-platform.org/) (an open-source IoT platform). Astarte handles device connectivity via MQTT; Edgehog provides the management layer.

---

## 2. Repository Structure

```
edgehog/
├── backend/                    # Elixir/Phoenix/Ash backend
│   ├── lib/
│   │   ├── edgehog/           # Domain logic (Ash resources, domains)
│   │   │   ├── devices/       # Device management
│   │   │   ├── containers/    # Container orchestration
│   │   │   ├── campaigns/     # OTA update campaigns
│   │   │   ├── groups/        # Device groups
│   │   │   ├── tenants/       # Multi-tenancy
│   │   │   └── astarte/       # Astarte integration
│   │   └── edgehog_web/       # Web layer (GraphQL, controllers)
│   │       ├── schema/        # Absinthe GraphQL schema
│   │       ├── resolvers/     # GraphQL resolvers
│   │       └── controllers/   # Admin REST API
│   ├── config/                # Application configuration
│   ├── priv/
│   │   ├── repo/migrations/   # Ecto migrations
│   │   └── repo/seeds.exs     # Seed data
│   └── test/                  # Test suites
├── frontend/                   # React/TypeScript frontend
│   ├── src/
│   │   ├── api/               # Relay GraphQL configuration
│   │   ├── components/        # React components
│   │   ├── pages/             # Page components (routes)
│   │   ├── forms/             # Form components & validation
│   │   ├── contexts/          # React contexts (auth, session)
│   │   └── i18n/              # Internationalization
│   └── public/                # Static assets
├── doc/                       # Documentation source
│   └── pages/                 # Markdown documentation
├── edgehog-astarte-interfaces/ # Astarte interface definitions (JSON)
├── charts/                    # Kubernetes Helm charts
├── tools/                     # Utility scripts
├── docker-compose.yml         # Local development stack
└── justfile                   # Development task runner
```

---

## 3. Backend Architecture

### Technology Stack

- **Elixir** 1.19+ / **Erlang/OTP** 28+
- **Phoenix** 1.7+ web framework
- **Ash Framework** 3.0+ (application framework)
- **PostgreSQL** 13+ (primary database)
- **Absinthe** (GraphQL)
- **Astarte Client** (IoT platform integration)

### Ash Framework Patterns

Edgehog uses [Ash Framework](https://www.ash-hq.org/) as its core application framework. This is **critical** to understand.

#### Domains and Resources

```elixir
# Domain (lib/edgehog/devices/devices.ex)
defmodule Edgehog.Devices do
  use Ash.Domain, extensions: [AshGraphql.Domain]

  resources do
    resource Edgehog.Devices.Device
    resource Edgehog.Devices.HardwareType
    resource Edgehog.Devices.SystemModel
  end

  graphql do
    queries do
      get Device, :device, :read
      list Device, :devices, :read, paginate_with: :keyset, relay? true
    end

    mutations do
      update Device, :update_device, :update
    end
  end
end

# Resource (lib/edgehog/devices/device/device.ex)
defmodule Edgehog.Devices.Device do
  use Edgehog.MultitenantResource,
    domain: Edgehog.Devices,
    extensions: [AshGraphql.Resource]

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:device_id, :name, :part_number]
    end
  end

  attributes do
    integer_primary_key :id
    attribute :device_id, :string, allow_nil?: false
    attribute :name, :string
    # ...
  end

  relationships do
    belongs_to :system_model, Edgehog.Devices.SystemModel
    belongs_to :tenant, Edgehog.Tenants.Tenant
  end
end
```

#### Multi-Tenancy

**All resources are multi-tenant.** Every resource that stores tenant-specific data uses `Edgehog.MultitenantResource` instead of `Ash.Resource`:

```elixir
defmodule Edgehog.MultitenantResource do
  defmacro __using__(opts) do
    quote do
      use Ash.Resource,
        data_layer: AshPostgres.DataLayer

      relationships do
        belongs_to :tenant, Edgehog.Tenants.Tenant do
          allow_nil? false
        end
      end

      multitenancy do
        strategy :attribute
        attribute :tenant_id
      end
    end
  end
end
```

**Critical**: When querying or changing resources, always include the tenant in the context:

```elixir
# Correct
Device
|> Ash.Query.for_read(:read)
|> Ash.read(tenant: tenant)

# Wrong - will fail or return wrong results
Device |> Ash.read()
```

#### Resource Section Order Convention

Resources follow a strict section order (configured in `config/config.exs`):

```elixir
resource_section_order: [
  :resource,        # Description, etc.
  :graphql,         # GraphQL type configuration
  :json_api,        # REST API configuration
  :code_interface,  # Define shortcuts
  :actions,         # CRUD actions
  :validations,     # Validation rules
  :preparations,    # Query preparations
  :attributes,      # Schema attributes
  :relationships,   # Associations
  :calculations,    # Computed values
  :aggregates,      # Aggregations
  :identities,      # Unique constraints
  :changes,         # Change callbacks
  :pub_sub,         # PubSub notifications
  :multitenancy,    # Tenant configuration
  :postgres         # Database-specific config
]
```

### Key Domains

| Domain | Path | Purpose |
|--------|------|---------|
| `Edgehog.Devices` | `devices/` | Device management, hardware types, system models |
| `Edgehog.Containers` | `containers/` | Container deployments, networks, volumes |
| `Edgehog.Campaigns` | `campaigns/` | OTA update campaigns |
| `Edgehog.Groups` | `groups/` | Device groups with selector queries |
| `Edgehog.Tenants` | `tenants/` | Multi-tenancy, tenant provisioning |
| `Edgehog.Astarte` | `astarte/` | Astarte API integration |
| `Edgehog.BaseImages` | `base_images/` | Firmware base images |
| `Edgehog.OSManagement` | `os_management/` | OS-level operations |

### Astarte Integration

Devices communicate via Astarte using standardized interfaces:

```
edgehog-astarte-interfaces/
├── io.edgehog.devicemanager.SystemInfo.json
├── io.edgehog.devicemanager.SystemStatus.json
├── io.edgehog.devicemanager.HardwareInfo.json
├── io.edgehog.devicemanager.BatteryStatus.json
├── io.edgehog.devicemanager.OTARequest.json
└── io.edgehog.devicemanager.apps.*.json
```

**Trigger Flow**:
1. Device connects/disconnects → Astarte sends HTTP trigger → Edgehog updates device status
2. Device publishes data → Astarte stores → Edgehog queries via REST API

### OTP Application Structure

```elixir
# lib/edgehog/application.ex
def start(_type, _args) do
  children = [
    Edgehog.Repo,                          # Database
    {Phoenix.PubSub, name: Edgehog.PubSub}, # PubSub
    EdgehogWeb.Endpoint,                    # HTTP server
    Edgehog.Campaigns.Supervisor,           # Campaign management
    Edgehog.Tenants.Reconciler.Supervisor,  # Tenant reconciliation
    Edgehog.Devices.Reconciler,             # Device state reconciliation
    # ...
  ]
end
```

### Testing

```bash
# Run all tests
mix test

# Run with coverage
mix coveralls

# Static analysis
mix credo
MIX_ENV=test mix dialyzer

# Format check
mix format --check-formatted
```

**Test Structure**:
- `test/edgehog/` - Domain tests
- `test/edgehog_web/` - Web layer tests
- `test/support/` - Test utilities, factories

---

## 4. Frontend Architecture

### Technology Stack

- **React** 18 with TypeScript (strict mode)
- **Vite** (build tool)
- **Relay** (GraphQL client)
- **React Router** v6
- **React Bootstrap** + **Tailwind CSS**
- **React Hook Form** + **Zod** (forms)
- **React Intl** (i18n)

### Directory Structure

```
frontend/src/
├── api/                       # Relay configuration
│   ├── index.ts              # Environment, fetch functions
│   ├── relay.ts              # Feature flags
│   ├── schema.graphql        # Backend schema (generated)
│   └── __generated__/        # Relay-generated types
├── components/               # Reusable components
│   ├── DeviceTabs/          # Device detail tabs
│   ├── Table.tsx            # Data table (TanStack)
│   └── *.tsx
├── pages/                    # Route components
│   ├── Devices.tsx
│   ├── Device.tsx
│   └── ...
├── forms/                    # Form components
│   ├── validation.ts        # Zod schemas
│   └── Create*.tsx
├── contexts/                 # Global state
│   ├── Auth.tsx             # Authentication
│   └── Session.tsx          # Session/cookies
└── i18n/                    # Translations
    ├── langs/en.json
    └── langs-compiled/
```

### Data Fetching with Relay

**Critical**: All GraphQL operations are colocated with components using Relay.

```typescript
// Query (route-level)
import { graphql, usePreloadedQuery, useQueryLoader } from 'react-relay';

const DevicesQuery = graphql`
  query Devices_Query($first: Int, $after: String) {
    devices(first: $first, after: $after) {
      edges {
        node {
          id
          name
          ...DeviceListItem_fragment
        }
      }
    }
  }
`;

// Fragment (component-level)
const DeviceListItemFragment = graphql`
  fragment DeviceListItem_fragment on Device {
    id
    name
    online
  }
`;

// Mutation
const UpdateDeviceMutation = graphql`
  mutation Device_Update_Mutation($id: ID!, $input: UpdateDeviceInput!) {
    updateDevice(id: $id, input: $input) {
      device { id name }
    }
  }
`;
```

**Important Patterns**:
- Always use fragments for component data needs
- Route-level queries load data; components use fragments
- Relay compiler generates TypeScript types automatically

### Routing

Routes are defined in `Navigation.tsx` with type-safe paths:

```typescript
enum Route {
  devices = '/devices',
  devicesEdit = '/devices/:deviceId',
  deviceGroups = '/device-groups',
  // ...
}
```

Used in `App.tsx`:
```typescript
const authenticatedRoutes: RouterRule[] = [
  { path: Route.devices, element: <Devices /> },
  { path: Route.devicesEdit, element: <Device /> },
  // ...
];
```

### Forms

Forms use React Hook Form + Zod:

```typescript
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';

const schema = z.object({
  name: z.string().min(1, 'Name is required'),
  tags: z.array(z.string()),
});

type FormData = z.infer<typeof schema>;

function DeviceForm() {
  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('name')} />
      {errors.name && <span>{errors.name.message}</span>}
    </form>
  );
}
```

### Development Commands

```bash
# Install dependencies and generate types
npm install
npm run init          # Compile Relay + i18n

# Development server
npm start             # Vite dev server on :3000

# Build
npm run build         # Production build

# Code quality
npm run check-types   # TypeScript check
npm run check-lint    # ESLint
npm run check-format  # Prettier
npm run test          # Vitest
npm run coverage      # Coverage report

# Update schema from backend
cd ../backend && mix absinthe.schema.sdl --schema EdgehogWeb.Schema ../frontend/src/api/schema.graphql
```

---

## 5. Domain Model

### Core Entities

```
Tenant
├── Devices
│   ├── SystemModel → HardwareType
│   ├── Tags
│   └── ApplicationDeployments
├── DeviceGroups (selector-based)
├── BaseImageCollections
│   └── BaseImages
├── UpdateCampaigns
│   └── UpdateTargets
├── Applications (containerized)
│   ├── Releases
│   ├── Channels (deployment tracks)
│   └── Deployments
├── Volumes
├── Networks
└── ImageCredentials
```

### Device Lifecycle

1. **Registration**: Device connects to Astarte → Trigger creates Device record
2. **Identification**: Device sends `SystemInfo` → Edgehog matches `part_number` to `SystemModel`
3. **Monitoring**: Device sends telemetry (status, battery, location)
4. **Operations**: OTA updates, container deployments, remote commands
5. **Decommission**: Device deleted or disconnected

### Key Astarte Interfaces

| Interface | Purpose |
|-----------|---------|
| `io.edgehog.devicemanager.SystemInfo` | Serial number, part number |
| `io.edgehog.devicemanager.SystemStatus` | Memory, uptime, tasks |
| `io.edgehog.devicemanager.HardwareInfo` | CPU, RAM, storage specs |
| `io.edgehog.devicemanager.BatteryStatus` | Battery level/state |
| `io.edgehog.devicemanager.Geolocation` | GPS coordinates |
| `io.edgehog.devicemanager.OTARequest` | OTA commands |
| `io.edgehog.devicemanager.apps.*` | Container management |

---

## 6. Development Workflows

### Local Development (with just)

```bash
# Full setup (Astarte + Edgehog + tenant)
just provision-tenant

# If you already have Astarte running
just provision-edgehog

# Start development servers
just dev-backend    # Phoenix on :4000
just dev-frontend   # Vite on :3000

# Connect a test device
just connect-device

# View logs
just logs           # Edgehog logs
just logs-astarte   # Astarte logs

# Clean up
just deprovision-tenant
```

### Manual Setup (without just)

```bash
# Backend
cd backend
mix deps.get
mix ecto.setup      # Create DB, run migrations, seed
mix phx.server      # Start server

# Frontend
cd frontend
npm install
npm run init        # Generate Relay types
npm start           # Start dev server
```

### Testing Strategy

**Backend**:
- Unit tests for domain logic
- Integration tests for Astarte interactions
- GraphQL API tests

```bash
cd backend
mix test                    # Run tests
mix test --failed          # Re-run failed
mix test test/edgehog/devices/device_test.exs:123  # Specific line
```

**Frontend**:
- Component tests with React Testing Library
- Relay mocking for data

```bash
cd frontend
npm test                    # Run tests (Vitest)
npm run coverage           # Coverage report
```

### Debugging

**Backend**:
```bash
# Interactive shell
iex -S mix phx.server

# Observer (GUI)
iex -S mix
:observer.start()

# Tracing
:recon_trace.calls({Edgehog.Devices, :_, :_}, 10)
```

**Frontend**:
```bash
# Relay dev tools
# Install browser extension: Relay DevTools

# Debug network
# Browser DevTools → Network → GraphQL requests
```

---

## 7. Conventions & Invariants

### Code Style

**Elixir**:
- Use `mix format` for formatting
- Follow Credo rules (run `mix credo`)
- Prefer pattern matching over conditionals
- Use `defstruct` for data structures, not raw maps
- Prefix private functions with `_` only when truly internal

**TypeScript/React**:
- Use Prettier for formatting
- Strict TypeScript mode enabled
- Prefer function components with hooks
- Use `const` for component definitions
- Destructure props in function parameters

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Elixir modules | PascalCase | `Edgehog.Devices.Device` |
| Elixir functions | snake_case | `fetch_device/1` |
| React components | PascalCase | `DevicesTable` |
| TypeScript functions | camelCase | `handleSubmit` |
| GraphQL types | PascalCase | `Device`, `UpdateDeviceInput` |
| Database tables | snake_case | `devices`, `base_images` |

### Ash Resource Conventions

1. **Always use `Edgehog.MultitenantResource`** for tenant-scoped resources
2. **Actions**: Define explicit actions; avoid `defaults [:read, :destroy]` unless simple
3. **Changes**: Place complex change logic in `changes/` subdirectory
4. **Validations**: Use `validations/` subdirectory for reusable validators
5. **Calculations**: Use `calculations/` for computed attributes
6. **GraphQL**: Always define `type` in `graphql do` block

### Git Conventions

- **Conventional Commits**: `type(scope): subject`
  - Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
  - Example: `feat(devices): add battery status monitoring`
- **Branch naming**: `feature/description`, `fix/description`, `chore/description`
- **REUSE compliance**: All files must have SPDX headers

### Critical Invariants

1. **Never break multi-tenancy**: Always include `tenant` in Ash operations
2. **Never expose internal IDs**: Use Relay-style global IDs in GraphQL
3. **Never skip migrations**: All schema changes require migrations
4. **Never commit secrets**: Use environment variables, never hardcode
5. **Never skip tests**: New features require tests

---

## 8. Common Pitfalls

### Backend

**❌ Wrong: Missing tenant context**
```elixir
Device |> Ash.read!()  # Returns wrong data or fails
```

**✅ Correct: Include tenant**
```elixir
Device |> Ash.read!(tenant: tenant)
```

**❌ Wrong: Using raw Ecto in resources**
```elixir
# In a change callback
Repo.get(Device, id)  # Bypasses Ash, breaks tenancy
```

**✅ Correct: Use Ash actions**
```elixir
Device
|> Ash.Query.for_read(:read)
|> Ash.Query.filter(id == ^id)
|> Ash.read_one!(tenant: tenant)
```

**❌ Wrong: Defining actions without primary check**
```elixir
actions do
  create :create  # Not marked as primary
end
```

**✅ Correct: Mark primary actions**
```elixir
actions do
  create :create do
    primary? true
  end
end
```

### Frontend

**❌ Wrong: Direct API calls**
```typescript
fetch('/api/devices')  // Don't do this
```

**✅ Correct: Use Relay**
```typescript
const data = usePreloadedQuery(DevicesQuery, queryRef);
```

**❌ Wrong: Prop drilling data**
```typescript
<DeviceDetails device={device} />  // Passing whole object
```

**✅ Correct: Use fragments**
```typescript
<DeviceDetails deviceRef={device} />  // Pass fragment ref

// Inside DeviceDetails:
const device = useFragment(DeviceDetailsFragment, deviceRef);
```

### Ash-Specific

**❌ Wrong: Modifying changeset directly**
```elixir
def change(changeset, _opts, _context) do
  %{changeset | attributes: %{changeset.attributes | name: "foo"}}
end
```

**✅ Correct: Use change helpers**
```elixir
def change(changeset, _opts, _context) do
  Ash.Changeset.change_attribute(changeset, :name, "foo")
end
```

**❌ Wrong: Manual transaction management**
```elixir
Repo.transaction(fn -> ... end)
```

**✅ Correct: Use Ash transactions**
```elixir
Ash.transaction([action1, action2], tenant: tenant)
```

---

## 9. How to Add a New Feature

### Example: Add "Device Notes" Feature

**Backend Changes**:

1. **Add attribute to Device resource** (`lib/edgehog/devices/device/device.ex`):
```elixir
attributes do
  # ... existing attributes ...
  attribute :notes, :string
end

actions do
  update :update do
    accept [:name, :notes]  # Add :notes
  end
end
```

2. **Generate migration**:
```bash
cd backend
mix ash.generate_migration add_device_notes
```

3. **Add GraphQL field** (already done via AshGraphql):
```elixir
graphql do
  type :device
  # notes field auto-exposed from attribute
end
```

4. **Run tests**:
```bash
mix test
mix credo
MIX_ENV=test mix dialyzer
```

**Frontend Changes**:

1. **Update Relay fragment** (`src/pages/Device.tsx`):
```typescript
const DeviceFragment = graphql`
  fragment Device_fragment on Device {
    id
    name
    notes  # Add this
    # ...
  }
`;
```

2. **Add form field** (`src/forms/UpdateDevice.tsx`):
```typescript
const schema = z.object({
  name: z.string(),
  notes: z.string().optional(),  // Add this
});

// In form:
<FormRow label="Notes">
  <textarea {...register('notes')} />
</FormRow>
```

3. **Regenerate Relay types**:
```bash
cd frontend
npm run relay:compile
```

4. **Test**:
```bash
npm run check-types
npm run check-lint
npm test
```

5. **Update schema** (if needed):
```bash
cd ../backend
mix absinthe.schema.sdl --schema EdgehogWeb.Schema ../frontend/src/api/schema.graphql
```

**Documentation**:

Add documentation in `doc/pages/user/` if user-facing, or update relevant sections.

---

## 10. Guidance for AI Agents

### Before Modifying Code

1. **Read the relevant domain file** in `backend/lib/edgehog/<domain>/`
2. **Check existing resources** for patterns (naming, structure, conventions)
3. **Understand tenant context** - all queries need tenant
4. **Review tests** in `backend/test/edgehog/<domain>/`
5. **Check GraphQL schema** in `frontend/src/api/schema.graphql`

### Safe Change Patterns

**Adding a new resource**:
1. Create resource file in appropriate domain subdirectory
2. Use `Edgehog.MultitenantResource` (not `Ash.Resource`)
3. Add to domain in `lib/edgehog/<domain>.ex`
4. Generate migration: `mix ash.generate_migration`
5. Add tests

**Adding a field to existing resource**:
1. Add attribute to resource
2. Add to `accept` list in relevant actions
3. Generate migration
4. Update GraphQL fragments in frontend
5. Update forms/UI as needed

**Adding a new API endpoint**:
- For GraphQL: Add to domain's `graphql do` block
- For Admin REST: Add to `lib/edgehog_web/controllers/admin/`

### When to Ask for Clarification

Ask the user when:
- The change spans multiple domains (e.g., devices + containers)
- It involves Astarte interface changes
- It affects authentication/authorization
- It requires database schema changes across many tables
- The feature doesn't fit existing patterns

### Generating Safe Diffs

1. **Run tests before and after** changes
2. **Use `mix format`** for Elixir, **Prettier** for TypeScript
3. **Check with `mix credo`** and **ESLint**
4. **Verify type safety** with `mix dialyzer` and `tsc --noEmit`
5. **Generate migrations** - never modify existing migrations

### Testing Checklist

Before submitting changes:

- [ ] Backend tests pass: `mix test`
- [ ] Frontend tests pass: `npm test`
- [ ] No lint errors: `mix credo`, `npm run check-lint`
- [ ] Type checking passes: `MIX_ENV=test mix dialyzer`, `npm run check-types`
- [ ] Code is formatted: `mix format`, `npm run format`
- [ ] New features have tests
- [ ] Documentation updated (if user-facing)

---

## Quick Reference

### Essential Commands

```bash
# Backend
cd backend
mix setup                    # deps.get + ecto.setup
mix phx.server              # Start server
mix test                    # Run tests
mix credo                   # Lint
MIX_ENV=test mix dialyzer   # Type check
mix format                  # Format
mix ash.generate_migration  # New migration

# Frontend
cd frontend
npm install                 # Install deps
npm run init               # Relay + i18n compile
npm start                  # Dev server
npm test                   # Run tests
npm run check-types        # TypeScript
npm run check-lint         # ESLint
npm run check-format       # Prettier
npm run relay:compile      # Regenerate Relay types

# Full stack (with just)
just provision-tenant       # Full setup
just dev-backend           # Backend only
just dev-frontend          # Frontend only
just connect-device        # Test device
just deprovision-tenant    # Clean up
```

### Key Files Reference

| Purpose | File |
|---------|------|
| Backend config | `backend/config/config.exs` |
| Ash domains | `backend/lib/edgehog/*.ex` |
| Device resource | `backend/lib/edgehog/devices/device/device.ex` |
| GraphQL schema | `backend/lib/edgehog_web/schema.ex` |
| Frontend entry | `frontend/src/index.tsx` |
| Routes | `frontend/src/Navigation.tsx` |
| Relay config | `frontend/relay.config.json` |
| GraphQL schema | `frontend/src/api/schema.graphql` |

---

*Last updated: 2026-02-06*
*Edgehog version: 0.11.0*
