# DFScrimPlanner Shared AI Knowledge

This directory is harness-neutral. Put durable project knowledge here when it should be usable by Codex, Claude Code, or any future coding agent.

## Shared Docs

- `api-routes.md` — migrated from `.claude/api-routes.md`.
- `auth-flows.md` — migrated from `.claude/auth-flows.md`.
- `codebase.md` — migrated from `.claude/codebase.md`.
- `common-tasks.md` — migrated from `.claude/common-tasks.md`.
- `dev-setup.md` — migrated from `.claude/dev-setup.md`.
- `drift.md` — migrated from `.claude/drift.md`.
- `features.md` — migrated from `.claude/features.md`.
- `schema.md` — migrated from `.claude/schema.md`.
- `troubleshooting.md` — migrated from `.claude/troubleshooting.md`.
- `workflow.md` — migrated from `.claude/workflow.md`.

## Harness-Specific Entry Points

- `../AGENTS.md` — Codex adapter.
- `../CLAUDE.md` — Claude Code adapter.
- `../.claude/` — Claude-native commands, settings, hooks, skills, and legacy docs.

## Migration Rule

Move knowledge here gradually. Do not mass-delete `.claude/**`; Claude Code still discovers commands, settings, hooks, and skills there.
