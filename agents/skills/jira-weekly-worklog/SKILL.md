---
name: jira-weekly-worklog
description: Record Jira worklogs after the user explicitly names one or more ticket keys and durations, then update parent-ticket Dev Progress from eligible child-ticket time tracking, treating DONE tickets as fully complete. Use when the user asks to log work, add time, or record time against Jira issues. For read-only weekly worklog reports or timesheets, use jira-weekly-worklog-report instead.
---

# Jira Weekly Worklog

Use the connected Jira MCP. Before handling a worklog request, invoke `jira-weekly-worklog-report`, then list the current user's In Progress and In Code Review tickets and present both results. Do not create or edit a worklog until the user explicitly names ticket key(s) and duration(s).

## Log work

After `jira-weekly-worklog-report` has displayed its complete report, list the current user's open work with JQL:

```jql
status in ("In Progress", "IN CODE REVIEW") AND assignee = currentUser() ORDER BY updated DESC
```

Request `summary`, `timespent`, `timeoriginalestimate`, and `timetracking`. Format each ticket as:

```markdown
- [KEY](url) — Summary — **logged time / estimated time**
```

Format absent logged or original estimated time as `0h`. Use Jira's original estimate, not remaining estimate. After presenting the ticket lists, provide a copyable template containing every current In Progress ticket, one per line, in this exact format: `KEY — Summary: ` (leave the duration blank). Do not include In Code Review tickets in this template. Then wait for the user to fill in one or more ticket durations. If a date is not specified, state that the log will use the current date and time, then create it. Use `addWorklogToJiraIssue` once per requested ticket, update the parent progress as specified below, and report each successful entry with its Jira link and duration.

Group the results under `In Progress:` and `In Code Review:` headings.

If the requested date or amount is ambiguous, ask a short clarifying question before writing.

## Update parent Dev Progress

After successfully logging work, skip this entire section when the logged ticket is a `Bug` or `Sub-Bug`; do not recalculate or update its parent Dev Progress. Also skip this entire section when the parent is a sprint Ad-hoc task titled `[PINK] Handle Ad-hoc Tasks During Sprint {number}`; never update Dev Progress on that parent. For other ticket types, update the parent automatically:

1. Fetch the ticket and read its `parent`. If it has no parent, do not update a progress field; state that no parent exists.
2. Search child tickets with JQL:

   ```jql
   parent = PARENT-KEY AND issuetype = "Sub-Imp"
   ```

   Request `status`, `timespent`, `timeoriginalestimate`, `timetracking`, and `assignee`. Include only `Sub-Imp` child tickets assigned to someone other than Louis (Tien) Le TPV (account ID `712020:d6c92603-c007-4ebd-8426-7a4f42b07603`); exclude all other child issue types and exclude Louis's Sub-Imp tickets from both the numerator and denominator.
3. For each eligible child ticket, calculate its contributed seconds: use its full original-estimate seconds when its status category is `Done`; otherwise, use its logged seconds. Calculate the display percentage as `round(min(100, total contributed seconds / total original-estimate seconds * 100))`. Convert it to the field value by dividing by `100`; for example, 63% must be written as `0.63`, not `63`.
4. If the total original estimate is zero or absent, do not update the field and report why. Do not substitute remaining estimates.
5. Set `customfield_17564` (`Dev Progress`, a numeric float) on the parent with `editJiraIssue`. Do not rediscover this field on each run. Write the fractional field value, such as `0.63` for 63%.
6. Report the parent key, display percentage, and written fractional value. Recompute separately after every successful worklog entry, including when more than one entry has the same parent.
