---
name: create-jira-adhoc-subtask
description: Create a Jira subtask beneath the active sprint's Ad-hoc ticket titled `[PINK] Handle Ad-hoc Tasks During Sprint {number}`. Use when a user asks to add, create, or log an ad-hoc subtask for the current/active sprint, especially when they provide a subtask type and title or expect them to be collected.
---

# Create Jira Ad-hoc Subtask

Create the requested Jira subtask under the Ad-hoc ticket for the active sprint and assign it to the requesting Jira user.

## Workflow

1. Collect the subtask type and title. If either is missing, ask only for the missing value(s) before making changes. Do not assume a type or invent a title. Before creation, normalize the supplied title to sentence case: trim surrounding whitespace and capitalize its first alphabetical character, while preserving the remaining wording and any intentional punctuation (for example, `fix bugs` becomes `Fix bugs`).
2. Get the requester with `mcp__jira__atlassianUserInfo` and retain their `account_id`.
3. Find the active sprint's parent ticket. Resolve the active sprint directly, then locate the matching PINK parent within it. Prefer a Jira search constrained to open sprints when available (for example, `project = CNPRD AND Sprint in openSprints() AND summary ~ "Handle Ad-hoc Tasks During Sprint" AND labels = Pink`); use Rovo Search with the exact stable title portion only as a fallback:

   ```text
   [PINK] Handle Ad-hoc Tasks During Sprint
   ```

   Select the issue whose title matches `[PINK] Handle Ad-hoc Tasks During Sprint {number}` and whose sprint is active. Do not ask the user for the sprint number merely because an unconstrained title search returns stale results; use the active-sprint query first. Ask only if the active-sprint query itself returns zero or multiple matching PINK parents.
4. Read `cloudId` from the search result metadata. Confirm the parent with `mcp__jira__getJiraIssue` when needed.
5. Validate the requested subtask type against `mcp__jira__getJiraProjectIssueTypesMetadata` for the parent project. Use the exact Jira type name (for example, `Sub-Bug`). If the requested type is unavailable, tell the user and ask them to choose one of the available subtask types.
6. Create the item using `mcp__jira__createJiraIssue` with:
   - `projectKey`: the parent issue's project key
   - `issueTypeName`: validated subtask type
   - `parent`: the Ad-hoc parent issue key
   - `summary`: normalized title from step 1
   - `assignee_account_id`: requester's `account_id`
7. Report the created key/link, its type, parent, and that it was assigned to the requester.

## Guardrails

- Create exactly one subtask per request unless the user explicitly asks for more.
- Treat creation as an external write: do not perform it if the target ticket or required fields remain ambiguous.
- Do not add a description, estimate, labels, sprint, priority, or transition unless the user explicitly asks.
