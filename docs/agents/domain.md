# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Source of Truth: Knowledge Base Submodule

All domain documentation lives in the **`docs/knowledgebase/`** Git submodule. This is the single source of truth — never modify it from this repo.

## Before exploring, read these

- **`docs/knowledgebase/CONTEXT-MAP.md`** — bounded contexts, relationships, communication patterns
- **`docs/knowledgebase/docs/contexts/<context>/CONTEXT.md`** — per-context domain docs (11 contexts: Identity, Contacts, Pipeline, Calendar, Activity, Automation, Products, Email, Files, Search, Reporting)
- **`docs/knowledgebase/docs/adr/`** — architectural decision records
- **`docs/knowledgebase/docs/specs/FRONTEND-SPEC.md`** — Flutter BLoC architecture, field rendering, routes, design system
- **`docs/knowledgebase/docs/specs/PRD.md`** — full product requirements

If any of these files don't exist, **proceed silently**. Don't flag their absence; don't suggest creating them upfront.

## File structure

Multi-context repo (knowledge base submodule):

```
/
├── docs/
│   ├── knowledgebase/                    ← Git submodule (source of truth)
│   │   ├── CONTEXT-MAP.md
│   │   ├── docs/
│   │   │   ├── adr/                      ← architectural decision records
│   │   │   ├── contexts/
│   │   │   │   ├── identity/CONTEXT.md
│   │   │   │   ├── contacts/CONTEXT.md
│   │   │   │   ├── pipeline/CONTEXT.md
│   │   │   │   └── ...                   ← 11 contexts total
│   │   │   └── specs/
│   │   │       ├── PRD.md
│   │   │       ├── FRONTEND-SPEC.md
│   │   │       ├── API-OVERVIEW.md
│   │   │       └── FOLDER-STRUCTURE.md
│   │   └── CLAUDE.md
│   └── agents/                           ← agent skill config (this repo)
└── lib/                                  ← Flutter app source
```

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in the relevant `CONTEXT.md`. Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, that's a signal — either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for `/grill-with-docs`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0007 — but worth reopening because…_
