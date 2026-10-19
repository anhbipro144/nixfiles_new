---
name: jira-weekly-worklog-report
description: Retrieve and display the current user's weekly Jira worklog report, including summaries of their In Progress and In Code Review tickets with logged time versus original estimate. Use when the user asks for a Jira worklog report, weekly timesheet, or logged-hours summary, without asking to create or change a worklog.
---

# Jira Weekly Worklog Report

Use the connected Jira MCP for read-only reporting. Do not create or edit worklogs.

## Report

1. Identify the current Jira account with `atlassianUserInfo` and resolve the accessible cloud ID when needed.
2. Fetch the current-week report with JQL:

   ```jql
   worklogAuthor = currentUser() AND worklogDate >= startOfWeek() AND worklogDate < startOfWeek(1) ORDER BY updated DESC
   ```

   Request `summary` and `worklog`. Sum only worklogs authored by the current user whose `started` timestamp is inside the current Monday–Sunday week in the user's Jira timezone. Do not use an issue's aggregate `timespent` for this report.
3. Present a current-week report with a total and Monday–Sunday daily columns. Derive weekdays from each `started` timestamp in the user's Jira timezone, aggregate by calendar date, and include each date in its header (for example, `Mon Aug 17`). Follow it with a ticket-level breakdown, one line per ticket, sorted by descending logged time. Always use this format:

   ```markdown
   Ticket breakdown:

   - [KEY](url) — Summary — Nh
   ```

   Aggregate each ticket's worklogs for the week before displaying its duration. Do not use an inline `Ticket totals:` sentence.
4. Follow the worklog breakdown with the current user's In Progress and In Code Review ticket summaries. Search with JQL:

   ```jql
   status in ("In Progress", "IN CODE REVIEW") AND assignee = currentUser() ORDER BY updated DESC
   ```

   Request `summary`, `timespent`, `timeoriginalestimate`, and `timetracking`. Display each ticket as:

   ```markdown
   In Progress:

   - [KEY](url) — Summary — **logged time / original estimate**

   In Code Review:

   - [KEY](url) — Summary — **logged time / original estimate**
   ```

   Use aggregate `timespent` and Jira's original estimate, not the reporting week's worklog total or remaining estimate. Format missing logged time or original estimate as `0h`.

If the Jira MCP is unavailable or disconnected, explain that the report cannot be fetched.
