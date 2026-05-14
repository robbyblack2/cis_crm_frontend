# CIS CRM Frontend

Flutter app (web primary, also iOS/Android). Uses the **BLoC pattern** (`flutter_bloc`) for all state management.

## Knowledge Base (Source of Truth)

The `docs/knowledgebase/` submodule is the **single source of truth** for all architecture, specs, and decisions. Before building any feature or making design decisions:

1. **Read freely** from `docs/knowledgebase/` — it contains all specs, ADRs, context maps, and domain docs
2. **Never modify** files in `docs/knowledgebase/` from this repo
3. If a spec needs changing, **stop and inform the user** — changes must be made in the knowledge base repo directly
4. If code conflicts with the knowledge base, **the knowledge base is authoritative**

### Key Documents

- `docs/knowledgebase/CONTEXT-MAP.md` — bounded contexts, relationships, tech stack
- `docs/knowledgebase/docs/specs/PRD.md` — full product requirements
- `docs/knowledgebase/docs/specs/FRONTEND-SPEC.md` — Flutter BLoC architecture, field rendering, routes, design system, UX patterns
- `docs/knowledgebase/docs/specs/FOLDER-STRUCTURE.md` — target folder structure
- `docs/knowledgebase/docs/specs/API-OVERVIEW.md` — REST API + WebSocket endpoints
- `docs/knowledgebase/docs/contexts/*/CONTEXT.md` — per-context domain docs (11 contexts)
- `docs/knowledgebase/docs/adr/` — architectural decision records

## BLoC Architecture

All development must follow the BLoC pattern as defined in `docs/knowledgebase/docs/specs/FRONTEND-SPEC.md`:

```
lib/features/<feature_name>/
  data/
    repositories/       # API calls, data source abstractions
    dtos/               # Data Transfer Objects (JSON serialization)
  domain/
    models/             # Domain models (immutable)
    bloc/
      <feature>_bloc.dart
      <feature>_event.dart
      <feature>_state.dart
  presentation/
    screens/            # Full-page widgets
    widgets/            # Reusable feature-specific widgets
```

## Agent skills

### Issue tracker

Issues are tracked in GitHub Issues on `robbyblack2/cis_crm_frontend`. See `docs/agents/issue-tracker.md`.

### Triage labels

Default label vocabulary (needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix). See `docs/agents/triage-labels.md`.

### Domain docs

Multi-context layout — `docs/knowledgebase/CONTEXT-MAP.md` at root of knowledgebase points to per-context `CONTEXT.md` files. See `docs/agents/domain.md`.
