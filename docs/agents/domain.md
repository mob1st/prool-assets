# Domain Docs

This is a single-context repository for Prool asset hosting conventions.

## Before Changing Conventions

Read these files when they exist:

- `CONTEXT.md` at the repository root.
- `docs/adr/` for decisions that affect asset storage, public paths, hosting, or deployment.

If either file does not exist, proceed silently. The domain glossary and ADRs are created lazily when terms or durable decisions are resolved.

## Expected Layout

```text
/
├── CONTEXT.md
├── docs/
│   └── adr/
└── AGENTS.md
```

## Use Project Language

Use the vocabulary defined in `CONTEXT.md` when naming folders, files, issues, pull requests, and documentation. If a needed term is missing, ask to resolve it before introducing a competing synonym.

## Flag Decision Conflicts

If a proposed change contradicts an ADR, call out the conflict explicitly and explain why the decision should be revisited.
