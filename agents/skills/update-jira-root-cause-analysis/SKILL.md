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
   - For NPRD bugs/sub-bugs, use `customfield_22948` ("Root Cause Type"). Do not use `customfield_10192`, which is deprecated.
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
   - Set `customfield_22948` (Root Cause Type) and `customfield_10193` (Dev Root Cause Analysis) with an edit call before transitioning. The transition fails with "Please provide both 'Root Cause Type' and 'Dev Root Cause Analysis'" if either is empty. Setting them with `editJiraIssue`, then transitioning with no fields, has worked. Passing `customfield_10192` in the transition call fails because that field is not on the transition screen.
   - If the ticket is already in `In Retest`, do not transition it again.
   - Use the available Jira transition tool with the validated transition id.
   - If no available transition reaches `In Retest`, report that the RCA fields were updated but the workflow does not permit the required transition.
12. Fetch the issue again and confirm the Root Cause Type, Dev Root Cause Analysis, and status are all set as intended before reporting success.
13. Report the PR, Jira issue key, Root Cause Type selected, Dev Root Cause Analysis text, and final status.

## Root Cause Type

Always retrieve the live allowed values from Jira metadata. Do not invent or send arbitrary strings.

Use `customfield_22948` (named "Root Cause Type"). It is the active field and is on the In Retest transition screen.

`customfield_10192` ("[Deprecated] Root Cause Type") is no longer valid. The transition screen rejects it with "cannot be set. It is not on the appropriate screen". Do not use it for new RCA updates.

Allowed values for `customfield_22948` (option ids from the In Retest transition metadata):

- `Requirement problem` (24395)
- `Design problem` (24396)
- `System / technical design problem` (24397)
- `DoD not followed` (24398)
- `Requirement, design, or system design not followed` (24399)
- `Requirement, design, or system design changed later` (24400)
- `Configuration error` (24401)
- `Integration error` (24402)
- `Third-party / external error` (24403)
- `Bad stored data (pre-existing)` (24404)
- `Production-only data` (24405)
- `Unmapped scenario / behavior` (24406)
- `Environment / infrastructure` (24407)
- `Code quality / standards issue` (24408)
- `Unknown / not yet determined` (24409)

Use the option object/id required by the edit tool. Validate the value against metadata first. If no option fits the RCA, ask the user to choose.

## Edit Pattern

Use this pattern first for NPRD RCA updates:

```json
{
  "cloudId": "oneline.atlassian.net",
  "issueIdOrKey": "CNPRD-21069",
  "contentFormat": "adf",
  "responseContentFormat": "markdown",
  "fields": {
    "customfield_22948": {
      "id": "24397"
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

If using the tool call directly, pass `fields.customfield_22948` and `fields.customfield_10193` as objects, not serialized JSON strings.

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

For `Root Cause Type`, set the selected option by id from metadata. Preferred shape:

```json
{
  "fields": {
    "customfield_22948": {
      "id": "24397"
    }
  }
}
```

Some Jira clients also accept `value`, but do not rely on it unless the object id form fails:

```json
{
  "fields": {
    "customfield_22948": {
      "value": "System / technical design problem"
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
