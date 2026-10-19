---
name: generate-testcase-pre-implementation
description: "Generate a pre-implementation, ticket-linked Markdown test-case baseline from a parent Jira ticket, its sub-implementation titles, and relevant source code, then create and populate a Google Sheets tab cloned from the designated template through Sheets MCP. Use before implementation begins."
---

# Generate Testcase Pre-implementation

Create a pre-implementation Markdown test-case baseline from a parent Jira ticket, its sub-implementation titles, and the current source code. Then create a new test-case tab from the designated Google Sheets template and enter the generated cases through Sheets MCP. This is a design artifact, not authorization to change production code or automated tests.

## Inputs

- **Parent Jira ticket: required.** Obtain a parent Jira URL or key before generating. A child implementation ticket does not substitute for its parent. If the parent is missing, ask for it and stop.
- **Google Sheets workbook: required.** Use [the test-case workbook](https://docs.google.com/spreadsheets/d/1Bpo8pKi5nZb9ue_XT2H2Py3AZeDsE3NGIx7GLHiXqxI/edit): spreadsheet ID `1Bpo8pKi5nZb9ue_XT2H2Py3AZeDsE3NGIx7GLHiXqxI`.
- **Template tab: required and read-only.** Clone [Format step by step](https://docs.google.com/spreadsheets/d/1Bpo8pKi5nZb9ue_XT2H2Py3AZeDsE3NGIx7GLHiXqxI/edit?gid=694927253#gid=694927253), `gid=694927253`.
- **Example tab: read-only reference.** Use [Example](https://docs.google.com/spreadsheets/d/1Bpo8pKi5nZb9ue_XT2H2Py3AZeDsE3NGIx7GLHiXqxI/edit?gid=172365843#gid=172365843), `gid=172365843`, to confirm the expected metadata and populated-row layout.

## Google Sheets direct-write contract

Use Sheets MCP to write the cases directly; do not produce a manual-paste handoff or ask the user to paste Markdown into another tool.

1. Before writing, use Sheets MCP to inspect the workbook, the protected `Format step by step` template (`gid=694927253`), and the protected `Example` tab (`gid=172365843`). Confirm their tab names, header rows, metadata rows, and representative test-case rows. If either tab cannot be identified unambiguously, stop and ask the user.
2. Create the destination tab by duplicating `Format step by step` within the same workbook. Name it `<JIRA-KEY> - Test Case Baseline`. Use `batch_update` with a `duplicateSheet` request, or an equivalent Sheets MCP operation that preserves the template's formulas, formatting, validation, and frozen panes. Never modify the template or example tab.
3. Before duplicating, list existing tabs. If a tab named `<JIRA-KEY> - Test Case Baseline` already exists, do not create a second tab; treat it as a refresh target. If its provenance or layout does not match the template, stop and ask the user.
4. Inspect the destination tab after duplication to identify its metadata cells, header row, first writable test-case row, existing columns, and strict data-validation lists. Use `include_grid_data: true` for every writable column that will receive categorical values. Populate ticket-level metadata where the template provides cells for it, following the example tab's layout.
5. Use only the destination tab's existing columns. Do not add columns or change headers, formulas, merged cells, formatting, wrapping, validation, frozen panes, column widths, or reviewer-entered fields.
6. **Strict-dropdown audit.** Never write a value outside a strict `ONE_OF_LIST` validation rule. For this workbook, write `Manual` in `Test type` unless the case is genuinely BDD, in which case write `Cucumber`; retain `Unit-test candidate`, `Integration-test candidate`, or `Manual / exploratory` as a labeled `Classification:` line in `Description`. Set `Pre-implementation` in `Label` only when it is an allowed option. Otherwise, use the permitted label that best matches the case (`Functional`, `Logical`, `API`, `Database`, or `Layout` in the current template) and retain `Baseline phase: Pre-implementation` in `Description` or ticket-level metadata. If no permitted value is a safe semantic match, stop and ask the user.
7. Map each generated case to the existing headers. Populate `Preconditions` and `Automation notes` as labeled, line-separated text in the existing `Description` cell when separate columns are not available. Preserve `Remark` for reviewer-entered notes.
8. For a refresh, locate rows by stable test-case ID and overwrite only generated fields. Do not overwrite reviewer remarks or unrelated rows.
9. Write through Sheets MCP (`update_cells`, `batch_update_cells`, or the appropriate equivalent), then read back the exact written range and verify the ticket metadata, IDs, descriptions, categorical values, and labels are present and permitted by their strict validation lists.

## Baseline workflow

1. Treat the parent ticket's description and acceptance criteria as the primary requirements source; use the parent key as the traceability anchor. Read linked/sub-implementation tickets and use their titles as supporting technical scope even when their descriptions are empty. Also consider relevant comments and attachments.
2. Inspect the current source code and existing tests for the scope identified by the ticket. Record behavior that exists today and distinguish it from intended behavior.
3. Create or refresh only `specs/test-cases/<JIRA-KEY>/<domain>/test-cases-pre-implementation.md`, using [references/test-case-template.md](references/test-case-template.md). Never overwrite a post-implementation artifact.
4. Clone the designated template tab and populate the new test-case tab through Sheets MCP using the direct-write contract above. Do not include a manual-paste handoff in the Markdown artifact.
5. Cover normal behavior, validation and error behavior, boundary cases, compatibility/regression risks, and cross-layer behavior where applicable. Keep each case traceable to a parent requirement or a current-code observation.
6. Give each case a stable ID such as `<JIRA-KEY>-<DOMAIN>-001`, classify it as Unit-test candidate, Integration-test candidate, or Manual / exploratory, and state priority, preconditions, steps, expected result, and traceability.

## Completion

After implementation, use `$generate-testcase-post-implementation` to create a separate post-implementation artifact. Keep this pre-implementation baseline unchanged for tracking and analysis.

Before delivering, verify that the Markdown artifact contains no manual-paste instructions and that a Sheets MCP readback confirms the generated rows were written to `<JIRA-KEY> - Test Case Baseline`. Report the new tab's URL and the written test-case IDs or row range.

## Guardrails

- Do not begin with only a child ticket; request the parent ticket.
- Do not modify, clone over, download, or export the protected template or example tab. Use only Sheets MCP to duplicate the template into a new destination tab and write generated rows there.
- Do not implement the feature, alter application code, or modify automated tests as part of baseline generation unless the user explicitly asks for those changes.
