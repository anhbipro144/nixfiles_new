---
name: nprd-fe-minimal-unit-tests
description: Write minimal Jest unit tests for the NPRD frontend codebase, especially when coverage fails scripts/check-coverage.js and only enough focused tests should be added to satisfy the 80% per-file coverage gate.
---

# NPRD FE Minimal Unit Tests

Use this when adding or fixing unit tests in the NPRD frontend repo.

## Goal

Add the smallest maintainable test coverage needed for the changed `src/**` files to pass:

```bash
yarn test:cov
yarn check-coverage
```

`scripts/check-coverage.js` reads `tests/reports/coverage/coverage-summary.json` and fails if any covered source file has less than 80% for lines, statements, branches, or functions.

## Workflow

1. Run or inspect coverage first:
   - `yarn test:cov`
   - `yarn check-coverage`
   - If coverage already exists, read `tests/reports/coverage/coverage-summary.json` and target only files below 80%.
2. Add tests under `tests/**` with the same feature path as the source file. Jest matches `tests/**/*.test.(js|ts|tsx)`.
3. Keep tests narrow:
   - Prefer pure function tests for helpers, mappers, validators, column builders, and hooks with simple outputs.
   - For React components, render only enough to cover conditional branches and callbacks.
   - Mock heavy UI libraries, GraphQL, router, browser APIs, and network calls at the test boundary.
   - Do not add broad integration flows just to raise coverage.
4. Cover the missing branch or function directly. One table-driven `it` is often enough.
5. Re-run the smallest relevant test command first, then `yarn test:cov && yarn check-coverage` when practical.

## Repo Conventions

- Test runner: Jest with `tests/setup/jest.config.js`.
- Environment: `jest-environment-jsdom`.
- Alias: import source via `@/src-path` style, for example `@/utils/string-helper`.
- Coverage source set: `./src/**`, with ignore patterns defined in `tests/setup/jest.config.js`.
- Coverage output: `tests/reports/coverage`.
- Existing tests often use `@testing-library/react`, `fireEvent`, `screen`, and simple `jest.mock(...)`.
- Test case descriptions in `it(...)` and `test(...)` must start with `should`, for example `it('should render empty state', () => { ... })`.

## Minimal Test Patterns

Pure function:

```ts
import { targetFn } from '@/path/to/source';

describe('targetFn', () => {
  it('should cover expected cases', () => {
    expect(targetFn(input)).toEqual(output);
    expect(targetFn(edgeInput)).toEqual(edgeOutput);
  });
});
```

React component:

```tsx
import { fireEvent, render, screen } from '@testing-library/react';

import { Component } from '@/path/to/component';

jest.mock('@ocean-network-express/magenta-react', () => ({
  Button: ({ children, onClick }: any) => (
    <button onClick={onClick}>{children}</button>
  ),
}));

it('should cover render and callback branch', () => {
  const onChange = jest.fn();

  render(<Component open={false} onOpenChange={onChange} />);

  fireEvent.click(screen.getByRole('button'));
  expect(onChange).toHaveBeenCalledWith(true);
});
```

Hook:

```tsx
import { renderHook, act } from '@testing-library/react';

import { useTargetHook } from '@/path/to/hook';

it('should cover state transition', () => {
  const { result } = renderHook(() => useTargetHook());

  act(() => result.current.setValue('x'));
  expect(result.current.value).toBe('x');
});
```

## Guardrails

- Do not chase 100% coverage unless the user asks.
- Do not snapshot large UI trees.
- Do not test library internals or generated GraphQL types.
- Do not rewrite production code for coverage unless a test exposes a real bug.
- Avoid excessive factories. Inline small props and data in the test.
- If branch coverage is the blocker, add explicit assertions for the missing condition rather than rendering a full workflow.
- Before finishing, scan added or edited test files and rename any `it(...)` or `test(...)` descriptions that do not start with `should`.
