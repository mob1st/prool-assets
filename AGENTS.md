# Prool Assets Agent Guide

This repository stores reviewed static assets for the Prool app.

## Agent Skills

### Issue Tracker

Work is tracked in Linear. See `docs/agents/issue-tracker.md`.

### Triage Labels

Linear labels map one-to-one to the agent triage vocabulary. See `docs/agents/triage-labels.md`.

### Domain Docs

This is a single-context repository. Read `CONTEXT.md` and relevant ADRs before changing asset conventions. See `docs/agents/domain.md`.

## Repository Rules

- Keep asset paths stable, public, and provider-agnostic.
- Add new published asset versions as new files, such as `v2.png`; do not overwrite existing published versions.
- Use the identifier and branch name provided by the Linear ticket.
- Keep the Linear identifier visible in commits, pull requests, and implementation notes.
- Prefer small, reviewable changes that can be verified independently.
