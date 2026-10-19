---
name: update-jira-root-cause-analysis
description: Read a GitHub PR, extract the Jira issue key from the PR description, then update that Jira ticket's Root Cause Type and Dev Root Cause Analysis fields and transition it to In Retest. Use when the user gives Codex a GitHub PR and asks to update RCA/root cause fields for the linked Jira ticket, especially for CHORUS NPRD Jira issues such as CNPRD-*.
---

# Update Jira Root Cause Analysis

Use this skill to update a Jira issue's root cause fields from a GitHub PR.

## Workflow

1. Fetch the GitHub PR from the URL or PR identifier provided by the user.
   - Prefer the GitHub MCP tool when available.
   - When a GitHub MCP tool is unavailable or cannot access the PR, use `gh pr view <number> --repo <owner>/<repo> --json title,body,commits,files` and `gh pr diff <number> --repo <owner>/<repo>`.
2. Read the PR title, description/body, commits, and diff.
3. Extract the Jira key from the PR title first.
   - Use keys like `CNPRD-21069`.
   - If the PR title has no Jira key, check the PR description/body.
   - If the PR description/body has no Jira key, stop and ask the user for the ticket.
4. Fetch the Jira issue with the available Jira connector to confirm access, status, project, and issue type.
5. Get issue type metadata for the issue's project and issue type before updating fields.
6. Write a short RCA from the PR behavior and diff.
7. Build `Dev Root Cause Analysis` as an Atlassian Document Format object before editing the issue.
   - For NPRD bugs/sub-bugs, this is usually `customfield_10193`.
   - This field requires ADF in the current Jira tool path; do not send plain markdown/text first.
8. Build `Root Cause Type` as a Jira option object before editing the issue.
   - For NPRD bugs/sub-bugs, this is usually `customfield_10192`.
   - This is a select field, not arbitrary text.
   - Set it only using one of the allowed option values returned by issue type metadata.
   - Send the validated option as an object, preferably `{ "id": "<option-id>" }`.
   - Choose the closest option based on the RCA. If uncertain, ask the user to choose.
9. Update both fields in a single call using the available Jira edit tool with `contentFormat: "adf"` and native JSON objects for both fields.
   - Do not pass the ADF document or option object as JSON strings.
   - Prefer `mcp__codex_apps__jira._editjiraissue` when it is exposed. Otherwise, use `mcp__jira__editJiraIssue` if its schema accepts object field values; verify the update response.
10. Fetch or inspect the edit response to confirm the update succeeded.
11. Transition the ticket to `In Retest`.
   - Fetch available transitions using the available Jira transitions tool (for example, `mcp__codex_apps__jira_gettransitionsforjiraissue` or `mcp__jira__getTransitionsForJiraIssue`).
   - Select the available transition whose destination status name is `In Retest` (case-insensitive and ignoring trailing whitespace); do not guess a transition ID.
   - If the ticket is already in `In Retest`, do not transition it again.
   - Use the available Jira transition tool with the validated transition id.
   - If no available transition reaches `In Retest`, report that the RCA fields were updated but the workflow does not permit the required transition.
12. Fetch the issue again and confirm the Root Cause Type, Dev Root Cause Analysis, and status are all set as intended before reporting success.
13. Report the PR, Jira issue key, Root Cause Type selected, Dev Root Cause Analysis text, and final status.

## Root Cause Type

Always retrieve the live allowed values from Jira metadata. Do not invent or send arbitrary strings.

For NPRD `Sub-Bug` issues, known allowed values include:

- `Not following AC/Description`
- `Absent or incomplete specification`
- `Ambiguous code`
- `Automated tests out project standards`
- `Code not compliant to with technology standards`
- `Code out of project standards`
- `Cross-browser / device incompatibility`
- `Document / comment out standard language`
- `Duplicate code`
- `Incomplete impact analysis`
- `Incomplete impact analysis after merge`
- `Insufficient or non-descriptive document / comment`
- `Integration missing or incorrect`
- `Layout refactor`
- `Logically incorrect`
- `Not following SCM or CI policies`
- `Obsolete code`
- `Obsolete document / comment`
- `Out of standards file name`
- `Out of standards method or variable name`
- `Requirement not followed`
- `Third party error`
- `User Interface not working`
- `Wrong content or encoding`
- `Wrong data manipulation`
- `Wrong layout and element position`
- `Wrong parameter configuration`
- `Change requirement/AC update`
- `Front-end UI not follow Figma`
- `Incorrect Figma design`
- `Figma update`
- `Back-end incorrect data manipulation`
- `Insufficient testing`
- `Wrong Parameter configuration (Deployment)`
- `Missing or incorrect integration`
- `Git merge/commit`
- `Incorrect design (UI/UX)`
- `Option Logically incorrect`
- `Technical solution was not clear`

Use the Jira option object/id required by the edit tool. If the edit tool accepts value names, still validate that the value appears in metadata first.

## Edit Pattern

Use this pattern first for NPRD RCA updates:

```json
{
  "cloudId": "oneline.atlassian.net",
  "issueIdOrKey": "CNPRD-21069",
  "contentFormat": "adf",
  "responseContentFormat": "markdown",
  "fields": {
    "customfield_10192": {
      "id": "10283"
    },
    "customfield_10193": {
      "type": "doc",
      "version": 1,
      "content": [
        {
          "type": "paragraph",
          "content": [
            {
              "type": "text",
              "text": "Root cause: ..."
            }
          ]
        },
        {
          "type": "paragraph",
          "content": [
            {
              "type": "text",
              "text": "Fix: ..."
            }
          ]
        }
      ]
    }
  }
}
```

If using the tool call directly, pass `fields.customfield_10192` and `fields.customfield_10193` as objects, not serialized JSON strings.

## In Retest Transition Pattern

Retrieve transitions before changing status; Jira workflow transition IDs are project- and status-specific.

```json
{
  "cloudId": "<cloud-id>",
  "issueIdOrKey": "CNPRD-21069",
  "transition": {
    "id": "<transition-id-to-IN-RETEST>"
  }
}
```

Use this only after confirming the RCA field update. Match `In Retest` against the transition destination status after trimming whitespace and normalizing case, not only its display name.

## ADF Textarea Pattern

Always use ADF for `Dev Root Cause Analysis`. Jira commonly rejects markdown with:

`Operation value must be an Atlassian Document`

Shape:

```json
{
  "cloudId": "<cloud-id>",
  "issueIdOrKey": "CNPRD-21069",
  "contentFormat": "adf",
  "responseContentFormat": "markdown",
  "fields": {
    "customfield_10193": {
      "type": "doc",
      "version": 1,
      "content": [
        {
          "type": "paragraph",
          "content": [
            {
              "type": "text",
              "text": "Root cause: ..."
            }
          ]
        },
        {
          "type": "paragraph",
          "content": [
            {
              "type": "text",
              "text": "Fix: ..."
            }
          ]
        }
      ]
    }
  }
}
```

## Select Field Pattern

For `Root Cause Type`, set the selected option using the id from metadata. Preferred shape:

```json
{
  "fields": {
    "customfield_10192": {
      "id": "10283"
    }
  }
}
```

Some Jira clients also accept `value`, but do not rely on it unless the object id form fails:

```json
{
  "fields": {
    "customfield_10192": {
      "value": "Logically incorrect"
    }
  }
}
```

## RCA Style

Keep the RCA short unless the user asks for detail:

```text
Root cause: <one sentence explaining the technical cause and impact>.

Fix: <one sentence explaining the code or configuration change>.
```

Use concrete component names, validation paths, PR numbers, and issue keys when known. Do not invent fields; verify field metadata when the issue type or project differs.
