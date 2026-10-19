---
name: create-jira-sub-implementation-tickets
description: Create Jira subtasks, sub-implementation tickets, sub-tickets, or child tickets under a parent Jira issue from ordered estimate/title rows; assign implementation tickets to the current user without changing the parent assignee, ask for and set the parent due date, calculate incremental child due dates from a user-provided start date using 7 working hours per day, then create the standard Ad-hoc and Cross testing and Verify DoD child tickets.
---

# Skill: Create Jira Sub-implementation Tickets With Test/DoD Follow-up

## Purpose

Create Jira sub-implementation tickets under a parent ticket from a list of `{estimate_hours, title}` rows, then create the standard test/DoD tickets under the same parent.

Do not change the parent ticket's assignee. Ask the user for the parent ticket's due date, then update it before creating or updating child tickets.

Each implementation ticket must:

- Be a sub-ticket/sub-task under the given parent issue.
- Preserve the exact title provided by the user.
- Set Original Estimate from the provided estimate hours.
- Assign the ticket to the current user.
- Set displayed due dates incrementally using working-time allocation.
- Exclude weekends and any user-provided days off or holidays from scheduling.
- Use 7 working hours per day unless the user provides a different value.

After all implementation tickets are created, the workflow must create these follow-up tickets if they do not already exist:

| Summary | Issue type | Original estimate | Assignee |
|---|---|---:|---|
| Ad-hoc and Cross testing | Sub-Test | 1h | Louis (Tien) Le TPV, `712020:d6c92603-c007-4ebd-8426-7a4f42b07603` |
| Verify DoD | Sub-Imp | 30m | Louis (Tien) Le TPV, `712020:d6c92603-c007-4ebd-8426-7a4f42b07603` |

Set priority to `Medium` for those follow-up tickets. Leave description empty unless the user provides one. Do not set due dates for those follow-up tickets unless the user explicitly asks for them.

## Trigger

Use this skill when the user asks to create subtasks, sub-impl tickets, sub-tickets, or child tickets under a Jira parent and provides estimates plus titles.

Example trigger:

> Create these sub-impl under parent ticket CNPRD-21830. Have original estimate, title as provided. Assign to me. Set incremental due dates from the start date I provide, excluding weekends. If I mention days off or holidays, skip those too. Worktime 7hr/day.

## Inputs

Required:

- `parent_issue_key`: Jira parent issue key.
- `parent_due_date`: parent ticket due date in `YYYY-MM-DD`; ask the user for it after resolving the parent and before making changes.
- `tasks`: ordered list of tasks:
  - `estimate_hours`: number
  - `title`: string
- `start_date`: first work date in `YYYY-MM-DD`.
- `hours_per_day`: default `7`.
- `exclude_weekends`: default `true`.
- `assignee`: current Jira user for implementation tickets only.

Optional:

- `non_working_dates`: user-provided days off or holidays to skip, in `YYYY-MM-DD`.

## Scheduling rules

1. Treat the task list as ordered and schedule cumulatively from `start_date`.
2. Allocate `hours_per_day` working hours per working day.
3. When `exclude_weekends` is true, skip Saturdays and Sundays entirely.
4. Skip any user-provided `non_working_dates` entirely.
5. For each task, compute the due date as the working date on which that task's cumulative allocated hours are completed.
6. If a task ends exactly at the end of a working day, use that same working day as the due date.
7. Carry partial-day remaining capacity into the next task.
8. Do not change the titles while creating Jira tickets.

## Jira creation procedure

Use Jira MCP as the source of truth before creating anything. The known Atlassian resource is `oneline` at `https://oneline.atlassian.net`, cloud ID `983cd706-e88f-407a-88c0-75f957a662d7`.

1. Resolve the Jira cloud ID with the accessible resources tool if the known cloud ID fails.
2. Resolve the parent issue:
   - Try the parent key exactly as the user provided it.
   - If the user says `NPRD-<number>` and Jira reports it does not exist, retry `CNPRD-<number>`.
   - If neither the exact key nor fallback resolves, stop and ask for the correct parent key.
3. Resolve the current Jira user for use as the assignee of implementation tickets. Do not assign, unassign, or otherwise modify the parent issue's assignee.
4. Ask the user: “What due date should I set for parent ticket `<resolved-parent-key>`? Please provide `YYYY-MM-DD`.” Do not create or update child tickets until the user answers.
5. Validate the supplied parent due date and update the parent issue's displayed due date field, using `customfield_10586` unless Jira metadata identifies a different accepted field.
6. Use the current Jira user as the assignee for implementation tickets.
7. Inspect the parent issue to determine the correct child issue type for implementation work, usually `Sub-Imp`, `Sub-task`, or the Jira project's configured sub-task type.
8. Search existing children with JQL like `parent = <resolved-parent> ORDER BY key ASC`.
9. For each input implementation task, create one child issue under `parent_issue_key` only if a matching child with the exact same summary does not already exist.
10. Set summary/title exactly to the supplied `title`.
11. Set Original Estimate to the supplied `estimate_hours` value in hours.
12. Set assignee to the current Jira user.
13. Set displayed due date custom field `customfield_10586` to the calculated incremental due date in Jira's expected `YYYY-MM-DD` date format.
14. After implementation tickets are created or confirmed existing, create the two test/DoD follow-up tickets listed in the template above, in that order, only when a matching summary does not already exist under the parent.
15. For test/DoD tickets, use the exact issue type, summary, assignee account ID, estimate, and priority from the template. Prefer account IDs over display-name lookup.
16. If Jira rejects a field name, original estimate, or issue type, inspect project metadata/edit metadata and retry with Jira's accepted field or issue type shape.
17. Do not create duplicate tickets if a retry occurs after partial success; first check whether matching child issues were already created under the parent.
18. Return a concise result with two tables:
   - Implementation tickets: title, estimate, due date, status (`created` or `already existed`), and Jira key.
  - Test/DoD tickets: summary, issue type, estimate, assignee, status (`created` or `already existed`), and Jira key.
  - Parent ticket: Jira key, existing assignee, due date, and status (`updated` or `already set`).

## Example input

```json
{
  "parent_issue_key": "CNPRD-21830",
  "parent_due_date": "<user-provided YYYY-MM-DD>",
  "start_date": "<user-provided YYYY-MM-DD>",
  "hours_per_day": 7,
  "exclude_weekends": true,
  "non_working_dates": ["<user-provided YYYY-MM-DD>"],
  "tasks": [
    {
      "estimate_hours": 14,
      "title": "FE - Implement Download Columns Selection dialog"
    },
    {
      "estimate_hours": 10,
      "title": "FE - Populate the dialog with columns data from Custom view"
    },
    {
      "estimate_hours": 14,
      "title": "FE - Update new ggdrive download logic"
    },
    {
      "estimate_hours": 8,
      "title": "FE - Update Show/hide columns tablev2 to exclude mandatory columns"
    }
  ]
}
```

## Example schedule result for the provided input

Starting on the user-provided `start_date`, using 7 hours per day, excluding weekends, and skipping any user-provided `non_working_dates`:

| Order | Estimate | Title | Due date |
|---:|---:|---|---|
| 1 | 14h | FE - Implement Download Columns Selection dialog | calculated from input |
| 2 | 10h | FE - Populate the dialog with columns data from Custom view | calculated from input |
| 3 | 14h | FE - Update new ggdrive download logic | calculated from input |
| 4 | 8h | FE - Update Show/hide columns tablev2 to exclude mandatory columns | calculated from input |

## Notes

- Jira field names vary by project and instance. Prefer metadata/tool inspection over guessing field IDs.
- The displayed due date field is confirmed as `customfield_10586`; use that field for due dates unless Jira metadata proves it is unavailable in the target project.
- Preserve task order because due dates are incremental.
- Do not assume a fixed start date. Ask for `start_date` if it cannot be inferred from the user's request.
- Always ask for `parent_due_date` after resolving the parent issue, even if the user supplied a date earlier; use their answer as the authoritative value.
- Only skip extra days off or holidays when the user provides them.
- Ask for missing required inputs only when they cannot be inferred from the user's request.
- Confirm created issue keys after creation.
- Preserve exact follow-up ticket capitalization and spelling, including `Ad-hoc and Cross testing`.
- Do not transition test/DoD tickets to `Done` unless the user explicitly asks for that.
