# AGENTS.md

## Project and worktree layout

This repository is the NPRD frontend application.

- Bare repository / Git common directory: `/home/neo/personal/work/NPRD/fe-bare`
- Local design-system source repo: `/home/neo/personal/work/NPRD/magenta`

Important: run Codex from the worktree path, not the bare repository path.

```bash
cd /home/neo/personal/work/NPRD/fe-bare/24874
codex
```

Codex should treat the worktree root as the project root. The bare repository is storage/metadata and should not be treated as the application source root.

## Application stack

- Framework: Next.js 14, React 18, TypeScript strict mode
- Package manager: Yarn 1.x
- Required Node version: `>=24.16.0`
- Main source directory: `src`
- Import alias: `@/*` maps to `src/*`

## Repository structure

Use the existing architecture before adding new folders or patterns.

- `src/domain`: domain use cases, hooks, and business-oriented logic
- `src/infrastructure`: GraphQL documents, generated types, clients, adapters, and external integration code
- `src/presentation`: UI implementation, split into atoms, molecules, organisms, layouts, and feature UI
- `src/pages`: Next.js pages/routes
- `tests`: Jest and Testing Library setup/tests
- `storybook`: Storybook configuration and UI documentation
- `env`: environment-specific `.env` files used by scripts

## Design system source of truth

Always prefer the organization design system before writing custom UI.

Primary source repo:

```bash
/home/neo/personal/work/NPRD/magenta
```

Before using a Magenta component, inspect the local source repo first:

1. Read `/home/neo/personal/work/NPRD/magenta/AGENTS.md`.
2. Inspect Magenta package source under `/home/neo/personal/work/NPRD/magenta/packages`.
3. Inspect matching stories/docs/examples in the Magenta repo.
4. Use `node_modules` only as a fallback for installed package exports and `.d.ts` files.

Installed UI/design-system packages in this app include:

- `@ocean-network-express/magenta-react`
- `@ocean-network-express/magenta-react-dates`
- `@ocean-network-express/magenta-react-icons`
- `@ocean-network-express/om-ui`
- `@ocean-network-express/om-nprd-ui`

Relevant Magenta source packages include:

- `/home/neo/personal/work/NPRD/magenta/packages/react`
- `/home/neo/personal/work/NPRD/magenta/packages/react-dates`
- `/home/neo/personal/work/NPRD/magenta/packages/react-icons`
- `/home/neo/personal/work/NPRD/magenta/packages/react-hooks`
- `/home/neo/personal/work/NPRD/magenta/packages/css`
- `/home/neo/personal/work/NPRD/magenta/packages/docs`

## UI implementation rules

Before implementing UI:

1. Search existing app usage under `src/presentation`.
2. Search Magenta source, stories, and docs under `/home/neo/personal/work/NPRD/magenta`.
3. Prefer existing Magenta/OM/NPRD UI components over raw HTML, custom Tailwind, or bespoke styled-components.
4. Reuse local components from `src/presentation/atoms`, `molecules`, and `organisms` before creating a new app-specific component.
5. Do not create custom Button, Input, Select, DatePicker, Modal/Dialog, Toast, Tabs, Table, Badge, Tooltip, Dropdown, Checkbox, Radio, or Pagination components unless no design-system or local component fits.
6. Keep visual styling aligned with existing component usage and Magenta/Panda CSS tokens.

## Figma-to-code workflow

When using Figma MCP or a Figma frame:

1. Use Figma for layout, hierarchy, spacing, copy, component names, and design intent.
2. Map Figma components to existing `@ocean-network-express/*` packages or local `src/presentation` components.
3. Inspect `/home/neo/personal/work/NPRD/magenta` before creating UI primitives.
4. Do not recreate design-system primitives from Figma screenshots.
5. Summarize which Figma elements mapped to which code components before large implementation changes.

## TypeScript and React conventions

- Keep TypeScript strict and avoid `any` unless the surrounding code already requires it.
- Prefer typed props and explicit return types for shared utilities.
- Follow existing import style and path alias conventions.
- Use React Hook Form and Yup/resolvers for forms when consistent with nearby code.
- Use Zustand patterns already present in the repository for client state.
- Use Apollo Client patterns already present in the repository for GraphQL data access.

## GraphQL rules

- Prefer existing generated GraphQL documents and types under `src/infrastructure/graphql`.
- Do not hand-write duplicate GraphQL result/request types when generated types already exist.
- After changing GraphQL documents, run the appropriate codegen script when available: `yarn codegen:local` or `yarn codegen:dev`.

## Table/UI feature rules

This codebase uses TanStack Table and related table abstractions. For table work:

- Inspect existing table implementations before adding new abstractions.
- Preserve existing patterns for column definitions, row selection, column visibility, pinning, sorting, pagination, drag/drop, and footer totals.
- Use `@tanstack/react-table` APIs directly only when local shared abstractions do not already cover the need.
- Keep table state predictable and avoid mixing unrelated concerns in one component.

## Implementation phase rule

During the implementation phase, prioritize completing the requested code change. Only add or update tests when the user asks for that in the current prompt. Avoid broad resource-heavy validation commands; prefer lightweight checks for touched files or targeted verification commands. The user will ask separately when broader validation is needed.

## Commands

Use the smallest reliable verification command for the change. Avoid broad resource-heavy validation commands unless explicitly requested.

Common commands:

```bash
yarn lint
yarn test
yarn build
yarn storybook:dev
```

Build scripts use files from `env/`. If required local configuration is unavailable, report that verification could not be completed instead of inventing results.

## Quality bar

Before finishing a task:

1. Explain the files changed.
2. Explain which design-system/local components were used.
3. Run lint/tests/build when practical.
4. Report any command that could not be run and why.
5. Do not claim verification succeeded unless the command actually completed successfully.

## Safety and repository hygiene

- Do not modify secrets, credentials, generated build output, or lockfiles unless the task explicitly requires it.
- Avoid large unrelated refactors.
- Keep changes scoped to the user request.
- Preserve existing formatting and naming conventions.
- Do not commit, push, or create PRs unless explicitly asked.
