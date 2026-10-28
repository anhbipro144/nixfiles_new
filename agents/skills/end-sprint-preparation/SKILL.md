---
name: end-sprint-preparation
description: Prepare the active Jira sprint by logging original estimates and completing C&A tickets assigned to the current user, then clearing remaining estimates on their Done tickets.
---

# End-sprint-preparation

Use the connected Jira MCP. Apply this workflow when the user asks to prepare their tickets for the end of the active sprint.

1. Resolve the current Jira account and accessible cloud ID. Search only the active sprint and the current user (`assignee = currentUser()`).
2. Find the user's C&A tickets with `sprint in openSprints() AND assignee = currentUser() AND summary ~ "C&A"`. For tickets not already in the Done status category, fetch the original estimate and current workflow transitions.
3. For each such ticket outside the Done status category with a positive original estimate, add one worklog equal to that estimate, using the current date and time in the user's Jira timezone as `started` unless the user specifies a date. Then transition it to the exact `Done` status by selecting the transition whose destination is `Done`. If the estimate is absent or zero, or no transition to `Done` is available, leave that ticket unchanged and report why. If logging fails, do not transition it. If the transition fails after logging, do not add a duplicate worklog on retry; verify the ticket and resume with the transition if the worklog succeeded.
4. Search the active sprint again for the current user's tickets with exact status `Done`. For each with a nonzero `timetracking.remainingEstimateSeconds`, set only `timetracking.remainingEstimate` to `0m` with `editJiraIssue`; preserve original estimate and time spent. Verify the changes.
5. Follow the `jira-weekly-worklog` skill's parent Dev Progress update procedure for every successful worklog when applicable. Report logged duration, resulting status, and any remaining-estimate updates, plus any tickets skipped with their reason.

Do not change assignees or tickets outside the active sprint. Do not log tickets already in the Done status category again.
