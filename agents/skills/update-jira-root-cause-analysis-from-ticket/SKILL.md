---
name: update-jira-root-cause-analysis-from-ticket
description: Start with a Jira issue key, find the GitHub PR that references it, analyze the PR diff, then set the Jira Root Cause Type and Dev Root Cause Analysis and transition the issue to In Retest or, when unavailable, Developed. Use when the user provides a Jira ticket such as CNPRD-21069 and asks to fill, update, or draft its RCA/root cause analysis without supplying a PR.
---

# Update Jira Root Cause Analysis From Ticket

Use this skill to complete an issue's RCA from its delivered GitHub pull request.

## Workflow

1. Fetch the Jira issue identified by the user. Confirm access, project, issue type, and current status.
2. Search GitHub for the exact Jira key in pull-request titles and bodies.
   - Use the `gh` CLI directly when available, for example `gh search prs CNPRD-21069 --limit 20 --json number,title,url,state,repository,body`. If the repository is known, scope with `--repo OWNER/REPO`.
   - Do not run `gh auth status` before the search: valid CLI credentials may exist even when status reports an inactive or stale account. If the actual search fails with an authentication error, then check `gh auth status` and report the access block.
   - Prefer GitHub MCP search only when `gh` is unavailable. Search both the exact key and the ticket URL if the first search is inconclusive.
3. Select the PR only when its title or description/body explicitly contains the exact Jira key.
   - Prefer a merged PR. If multiple merged PRs match, prefer the PR whose diff directly resolves the issue described in Jira and use its merge date, linked branch, and changes as corroboration.
   - If no PR matches, stop and report that no qualifying PR was found. Do not draft or update an RCA from ticket text alone.
   - If multiple candidates remain equally plausible, present their numbers, titles, URLs, and merge states, then ask the user to choose.
4. Read the selected PR's title, description/body, commits, files changed, and diff. Use the Jira issue description and acceptance criteria only as context; derive the root cause and fix from the delivered code.
5. Draft a concise RCA:

   ```text
   Root cause: <technical cause and impact>.

   Fix: <implemented code or configuration change>.
   ```

   Use concrete component names, validation paths, PR number, and ticket key where known. Do not invent causes or claim the fix prevented issues not supported by the diff.
6. Retrieve issue-type metadata for the issue's project and issue type before editing. Get the live allowed `Root Cause Type` values; never invent an option.
7. Select the closest Root Cause Type based on the RCA. If more than one allowed value is equally plausible, ask the user to choose rather than guessing.
8. Build `Dev Root Cause Analysis` as an Atlassian Document Format (ADF) object and `Root Cause Type` as a Jira select-option object.
   - For NPRD bugs/sub-bugs, these are usually `customfield_10193` and `customfield_10192`, respectively.
   - Use the select option id from metadata, preferably `{ "id": "<option-id>" }`.
9. Update both fields in one editor call with `contentFormat: "adf"`.
   - Prefer `mcp__codex_apps__jira._editjiraissue` when it is available.
   - Otherwise use `mcp__jira__editJiraIssue`; it supports native JSON ADF documents and select-option objects in this environment.
   - Pass the ADF document and select object as native JSON objects, never JSON strings, then retrieve the issue to confirm the saved values.
10. Confirm the edit succeeded. Retrieve available transitions and transition the issue only after the field update.
   - Select the transition whose destination status name is `IN RETEST` case-insensitively; do not guess its id.
   - If already In Retest, do not transition again.
   - If no transition reaches In Retest, select a transition to `DEVELOPED` case-insensitively when available, then report that In Retest was not directly reachable.
   - If neither status is available, report that the RCA fields were updated but the workflow prevented a transition.
11. Fetch the issue again and confirm the final field values and resulting status before reporting success. Include the ticket, selected PR, Root Cause Type, RCA text, and final status. Never transition the ticket to Done as part of this skill.

## Jira Update Pattern

Use this pattern after obtaining live field metadata. The custom-field ids below are NPRD examples; verify them for other projects or issue types.

```json
{
  "cloudId": "oneline.atlassian.net",
  "issueIdOrKey": "CNPRD-21069",
  "contentFormat": "adf",
  "responseContentFormat": "markdown",
  "fields": {
    "customfield_10192": {
      "id": "<validated-option-id>"
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

## Post-RCA Transition Pattern

Fetch transitions first and use the id whose destination status is `IN RETEST`. If unavailable, use `DEVELOPED`. Never select `DONE`.

```json
{
  "cloudId": "<cloud-id>",
  "issueIdOrKey": "CNPRD-21069",
  "transition": {
    "id": "<transition-id-to-IN-RETEST-or-DEVELOPED>"
  }
}
```
