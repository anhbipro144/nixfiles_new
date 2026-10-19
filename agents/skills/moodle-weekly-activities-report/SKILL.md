---
name: moodle-weekly-activities-report
description: Generate or refresh a simple Markdown report of Moodle activity completion for a requested semester week across all enrolled courses. Read the semester ID from the current directory's AGENTS.md and use Moodle CLI, including its authenticated client when the CLI omits completion fields.
---

# Moodle Weekly Activities Report

Create a course-by-course checklist for the requested week, using current Moodle completion states. Keep the report simple: headings, `Activities:`, and one bullet per activity. Do not use tables.

## Resolve the semester and week

- Read `AGENTS.md` in the working directory. Use its `Semester ID` value, accepting `:` or `=`; do not hard-code a semester or infer one from the directory name. Ask only if the value is missing or conflicting.
- Use the requested week number. For “this week”, resolve the teaching week from the current semester schedule or current dated Moodle sections. Do not calculate it from the course enrollment/start timestamp: these can predate teaching. If the week cannot be established, ask for its number.
- Include every enrolled course whose code/name has the semester prefix, even when there is no corresponding local course folder.
- Find sections named `Tuần N`, `Week N`, or `Tuan N`, including nested sections and online meeting sections. Match the exact number; Week 3 must not match Week 13 or Chapter 3 in a different week. If a course lacks a matching section, report that explicitly rather than assuming no work exists.

## Read live completion states

Use the installed `moodle` command first. Check `auth status --json`, `units list --json`, and relevant command help. If its shortcut is broken, invoke a discovered local CLI build through Node. On this machine the known checkout is `/home/neo/personal/reschool/moodle/moodle-cli`; verify it exists rather than assuming it.

If sandbox access reports no session, retry the read-only query with host/keyring access before requesting another login. Never print cookies, tokens, sesskeys, or cache contents.

The observed CLI `activities list` projection drops `completion`, even though its underlying client supplies it. A list without that field is not evidence of incomplete activities. Use the bundled collector when this occurs:

```sh
node <skill-directory>/scripts/collect-week.mjs \
  --week 3 --directory "$PWD" \
  --repository /path/to/moodle-cli --site https://your-moodle-site
```

Supply the real CLI checkout and the site returned by `auth status`. The collector uses that checkout's existing client, authentication, and esbuild; it reads the semester from `AGENTS.md`, discovers all semester courses and exact week sections, and returns sanitized JSON. It fetches full course contents rather than relying on activity-list limits. Process its output with context-mode and surface only the derived checklist. If a CLI upgrade exposes reliable completion fields directly, those are also suitable.

- State `0`: **not done**.
- State `1`: **done**.
- State `2`: **done — passed**.
- State `3`: **done — failed**; do not describe it as passed.
- Missing/unknown state: **status unavailable**. Never turn missing data into `not done`.
- Keep locked activities in the report: `not done — locked` or `done — locked`, as appropriate. Only name a prerequisite when actual Moodle evidence provides it.
- Omit `label` and `subsection` containers from completion totals. Include their real child activities. Preserve informative meeting dates separately; a meeting label is not an attended event.
- Keep every lesson separate, including the individual videos within a chapter. Deduplicate module IDs and reconcile per-course and overall totals.

Reporting is read-only. Do not mark checkboxes, invoke `view`, start/answer/submit quizzes, or post in forums. Module detail pages can record automatic views: avoid opening them merely to enrich a report. Use read-only course metadata or other status APIs instead. A separate completion request must follow the current user's authorization and `AGENTS.md` instructions.

`done` means Moodle's completion flag, not necessarily an attempted quiz, submitted assignment, watched lesson, or posted discussion. Add these facts only when verified separately. If a quiz is manually done and attempt evidence is unavailable, say `done — attempt status not checked`. A redirect returning course/portal metadata is not a valid assessment detail.

## Write the report

Save in the working directory as `activities-week-N.md`, or `activities-week-N-YYYY-MM-DD.md` when the week's start date is verified. When refreshing, update the existing report for that week rather than creating a second dated copy. Include the semester ID, requested week, and check timestamp/timezone. Do not invent calendar dates from stale labels or enrollment dates.

Under each course heading, include `Course ID: <id>` using the Moodle course ID (the collector's course-level `id`), not the course code, section ID, or activity/module ID.

Example shape:

```markdown
# Semester 2671 — Week 3 activities

Checked: 3 October 2026, Vietnam time.
27 done · 21 not done · 0 status unavailable

## Software requirements

Course ID: 1892

Activities:

- Chapter 3 video, lesson 1: not done
- Chapter 3 video, lesson 2: not done — locked
- Slides: not done
- Discussion: done
- Quiz: done — attempt status not checked
```

Use familiar course titles and concise activity names that still identify the module; add normal Moodle links for actionable items when useful. Include all semester courses, including failures or missing-week notices. Optional deadline bullets must use verified dates and statuses. An upcoming deadline feed covers future actionable events, not all deadlines in a historical/requested week; state that scope instead of claiming no deadlines existed.

## Due activities section

Add a `## Due activities` section after the summary lines and before the first course heading. Source it with `moodle due --days 365 --limit 200 --json`, the CLI maximum window. Keep only items whose due date falls inside the requested week, and list each as a bullet with course, activity name, and due date/time. If none fall in the week, write `None` on its own line. Always add a scope line naming the command and date checked, and note that the feed only covers future deadlines, so past deadlines in the requested week are not covered. Optionally name the nearest upcoming deadline outside the week for context.

Preserve verified submission/attempt notes in an existing report only when still applicable, with their original timestamps. Refresh every mutable completion state. If a course fetch fails, mark it `status unavailable` and exclude it from known-state counts; do not silently drop it or reuse old states as current. Verify totals and that no tables or activity omissions remain, then return a link to the file.
