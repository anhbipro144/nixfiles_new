---
name: draft-commit-message
description: Read the Git staged diff and draft an accurate, concise commit message. Use when the user asks to write, suggest, or improve a commit message for changes already staged with Git.
---

# Draft Commit Message

Inspect the staged changes only; do not stage, unstage, commit, or modify files.

## Workflow

1. Run `git diff --cached --stat` and `git diff --cached` from the repository root. If either command indicates there are no staged changes, say so and do not invent a message.
2. Summarize the intent of the staged changes, including the main behavior or user-facing outcome. Do not describe unstaged changes.
3. Choose exactly one prefix: `feat`, `update`, `refactor`, `chore`, or `fix`. Draft a single imperative commit subject as `{prefix}: {message}`. Keep it concise (aim for 72 characters or fewer) and do not add a trailing period.
4. Add a short body only when it makes the change materially clearer. Wrap body lines near 72 characters and explain *why* where the diff establishes it.

## Output

Return the commit message in a Markdown code block, ready to paste into Git. State any uncertainty briefly outside the code block. Always use the required prefix format, even if the repository uses another convention.
