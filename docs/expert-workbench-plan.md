# HomeMind Expert Workbench Plan

## Purpose

Add an AI expert workbench to HomeMind, inspired by Tencent WorkBuddy's
"Expert" and "Expert Group" capabilities.

- An **Expert** is a specialized AI agent with a defined role, methodology,
  tool policy, and output format. It is suited to a focused task.
- An **Expert Group** is a captain-led, multi-agent workflow. The captain
  breaks down a complex goal, routes work to members, and consolidates a
  final deliverable.
- A **Skill** is a tool capability, such as web search, document generation,
  calendar access, or spreadsheet processing. Skills are not agents.

The first release must provide observable, controllable workflows. It must not
expose a black-box multi-agent process to the user.

## Scope

### First release

- Built-in expert catalog with categories, search, detail views, and favorites.
- Built-in expert groups for weekly planning, goal decomposition, and review.
- Text-first task execution with progress events and final structured results.
- Convert a result into HomeMind plans, todos, or calendar events.
- Per-run usage estimate, actual usage record, cancellation, and retry.
- User-owned files as optional task context.

### Deferred

- User-created public experts and an open marketplace.
- Cross-tenant sharing.
- Automatic third-party actions without explicit confirmation.
- Full RAG knowledge-base management and external connectors.
- Unbounded autonomous loops.

## Product Model

| Object | Definition | Best for |
| --- | --- | --- |
| Skill | A reusable tool capability for an AI model. | Giving an agent an ability. |
| Expert | A single AI agent with a professional role and method. | A focused, single-domain problem. |
| Expert Group | A captain plus specialized members and a workflow. | A complex task that needs several roles. |

Initial built-in experts:

- Goal decomposition coach
- Daily and weekly planner
- Review analyst
- Todo organizer
- Habit coach
- Information organizer

Initial expert groups:

- Weekly planning group
- Goal decomposition group
- Personal review group

## User Flow

```text
Select expert or expert group
        |
Describe goal and attach optional context
        |
Confirm scope and estimated credits
        |
Create immutable execution run
        |
Single expert executes directly
Expert group captain produces a step DAG
        |
Members execute eligible steps in parallel
        |
Captain synthesizes and checks the result
        |
Show result and let the user create plans, todos, or events
```

Run state machine:

```text
draft -> queued -> planning -> running -> synthesizing -> completed
                  |            |              |
                  +-> failed   +-> cancelled  +-> needs_input
```

## Frontend Design

### Navigation

Do not add another bottom navigation item. Upgrade the existing Plan section
to **Plan and Experts**, with a segmented control:

- My Plans
- Expert Center

### Expert Center

- Search field and category filters.
- Expert / Expert Group segmented filter.
- Compact catalog cards with name, domain, expected deliverable, time estimate,
  and credit estimate.
- Detail bottom sheet or page with method, available tools, example tasks,
  privacy scope, expected output, and start action.
- Expert group detail shows captain, members, responsibilities, workflow
  summary, and the higher credit estimate.

### Create Run

- Natural-language task input.
- Optional references to existing todos, plans, calendar events, and files.
- Clear permission and usage confirmation before a run starts.
- A structured optional form only where the selected expert needs it.

### Execution View

- A full-width status timeline instead of nested cards.
- For groups, show captain planning, each member's assigned step, dependency
  wait state, current activity summary, and completion state.
- Provide cancel and retry actions when valid for the current state.
- Never expose raw chain-of-thought; show a concise plan and user-safe activity
  summaries only.

### Result View

- Executive summary.
- Generated action items and source references.
- Primary actions: Save as Plan, Create Todos, Add Calendar Events, Retry.
- Generated files are available through signed download URLs.

### Visual Direction

Continue the app's dark productivity aesthetic and restrained accent colors.
Catalog cards should be compact repeated content. Workflow progress should use
stable rows and a timeline so changing labels cannot move surrounding UI.

## Backend Architecture

The planned backend is ASP.NET Core with EF Core and SQL Server. Use a
background worker and durable job queue for execution. The API creates and
observes work; it does not execute model calls in the request thread.

```text
Flutter client
    |
REST API + SSE
    |
Expert run service ---- SQL Server
    |
Durable queue / worker ---- model providers and approved skills
    |
Object storage for uploads and generated artifacts
```

The group captain produces a directed acyclic graph (DAG). The scheduler starts
a step only when its dependencies are completed. Independent steps run in
parallel, subject to tenant concurrency and credit limits.

## Data Storage

### SQL Server

Store tenant-scoped structured data, immutable version references, status,
usage records, and user-visible audit events in SQL Server.

### Object Storage

Store uploaded context files, generated documents, images, spreadsheets, and
large result bodies in Tencent COS or another S3-compatible object store. SQL
stores only object keys, hashes, MIME types, sizes, and access metadata.

### Sensitive Data

- Connector secrets are encrypted at rest and isolated from run logs.
- Prompts and generated results follow tenant retention settings.
- Do not persist raw model chain-of-thought.
- Persist user-visible plan summaries, tool summaries, error codes, and cost
  records for troubleshooting and audit.

## Database Model

All IDs should use UUIDs. All tenant-owned tables must include `tenant_id`.
All mutable rows should include `created_at`, `updated_at`, and optimistic
concurrency support where appropriate.

```text
experts 1---N expert_versions
expert_groups 1---N expert_group_versions
expert_group_versions N---N expert_versions through expert_group_members

expert_runs 1---N run_steps
run_steps N---N run_steps through run_step_dependencies
expert_runs 1---N run_events
expert_runs 1---N run_artifacts
expert_runs 1---N credit_ledger
```

### Catalog Tables

| Table | Important columns | Notes |
| --- | --- | --- |
| `experts` | `id`, `tenant_id`, `code`, `name`, `category`, `type`, `status` | Expert identity. `type` is `builtin` or `custom`. |
| `expert_versions` | `id`, `expert_id`, `version`, `persona`, `methodology`, `prompt_template`, `tool_policy_json`, `knowledge_profile_json` | Immutable expert configuration. |
| `expert_groups` | `id`, `tenant_id`, `code`, `name`, `captain_expert_id`, `status` | Expert group identity. |
| `expert_group_versions` | `id`, `group_id`, `version`, `orchestration_policy_json`, `output_schema_json` | Immutable group workflow and expected output. |
| `expert_group_members` | `group_version_id`, `expert_version_id`, `role`, `order_no`, `is_required` | Captain and member responsibilities. |
| `user_expert_preferences` | `user_id`, `expert_id`, `is_favorite`, `last_used_at` | Favorites and recency. |

### Execution Tables

| Table | Important columns | Notes |
| --- | --- | --- |
| `expert_runs` | `id`, `tenant_id`, `user_id`, `source_type`, `source_version_id`, `input_json`, `status`, `plan_summary`, `result_json`, `estimated_credits`, `actual_credits` | Root record for every execution. |
| `run_steps` | `id`, `run_id`, `parent_step_id`, `expert_version_id`, `step_type`, `title`, `status`, `input_json`, `output_json`, `started_at`, `finished_at` | Individual expert work in a run. |
| `run_step_dependencies` | `step_id`, `depends_on_step_id` | Explicit DAG dependency edges. |
| `run_events` | `id`, `run_id`, `step_id`, `sequence`, `event_type`, `display_payload_json`, `created_at` | Ordered, user-safe real-time events. |
| `run_artifacts` | `id`, `run_id`, `step_id`, `object_key`, `sha256`, `mime_type`, `size_bytes`, `metadata_json` | Metadata for file outputs and context. |
| `credit_ledger` | `id`, `tenant_id`, `user_id`, `run_id`, `entry_type`, `amount`, `idempotency_key`, `created_at` | Estimate, charge, refund, and reconciliation. |

### Future Knowledge and Connector Tables

| Table | Important columns | Notes |
| --- | --- | --- |
| `knowledge_sources` | `id`, `tenant_id`, `owner_user_id`, `name`, `object_key`, `status` | Source file or URL metadata. |
| `knowledge_chunks` | `id`, `source_id`, `content`, `embedding_ref`, `chunk_index` | Enable only after a vector-search choice is made. |
| `connector_credentials` | `id`, `tenant_id`, `user_id`, `connector_type`, `secret_ciphertext`, `expires_at` | Encrypted third-party credentials. |

## API Contract

- `GET /api/v1/experts`: browse and search experts and groups.
- `GET /api/v1/experts/{id}`: get catalog detail and current version.
- `POST /api/v1/expert-runs`: validate and queue a run.
- `GET /api/v1/expert-runs/{id}`: retrieve run snapshot and final result.
- `GET /api/v1/expert-runs/{id}/events`: stream SSE progress events.
- `POST /api/v1/expert-runs/{id}/cancel`: cancel pending and running work.
- `POST /api/v1/expert-runs/{id}/retry`: retry eligible failed steps.
- `POST /api/v1/expert-runs/{id}/actions`: convert output to HomeMind data.

Every mutating request must accept an idempotency key. Every endpoint must
enforce user and tenant ownership before returning run data or artifact URLs.

## Delivery Plan

### Phase 1: Domain Contract and UI Prototype

- Add the domain models, DTOs, API interfaces, state machine, and mock data.
- Build Expert Center, detail, create-run, execution, and result screens.
- Use a deterministic mock run timeline for UI testing.

### Phase 2: Catalog and Single Expert

- Create database migrations and seed built-in experts.
- Implement catalog, favorite, create-run, and result APIs.
- Implement one single-expert workflow end to end.

### Phase 3: Expert Group Orchestration

- Create group/version/member tables and seed three groups.
- Implement DAG creation, scheduling, SSE events, cancel, and retry.
- Enforce concurrency and credit limits.

### Phase 4: Artifact and HomeMind Integration

- Add file upload and artifact delivery through object storage.
- Convert results into plans, todos, and calendar events.
- Add traceability from HomeMind records back to their source run.

### Phase 5: Advanced Capabilities

- Add knowledge sources, connectors, custom experts, and tenant governance.
- Add operational metrics, retention controls, and an admin catalog workflow.

## Acceptance Criteria

- A user can find an expert or group, understand its output and estimated cost,
  and submit a task from the mobile app.
- A group run visibly displays its plan, assigned steps, progress, and final
  consolidated result.
- The user can cancel or retry a run without duplicating charges.
- A final result can create HomeMind plans, todos, or calendar events.
- Every run can be traced to its immutable expert/group version, inputs,
  user-visible events, artifacts, and credit ledger entries.
- Unauthorized users cannot access another user's runs, files, or credentials.

## Risks and Guardrails

- **Cost:** Estimate before execution; ledger entries must be idempotent.
- **Slow or failed models:** Use queue-backed retries, timeouts, and step-level
  failure states.
- **Data exposure:** Explicitly show context scope; use signed object URLs and
  encrypted connector secrets.
- **Unreliable output:** Label AI output as a suggestion and require explicit
  confirmation before writing calendar or task data.
- **Observability:** Keep concise audit summaries and tool results, not private
  model reasoning.
