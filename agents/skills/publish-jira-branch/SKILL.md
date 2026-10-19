---
name: publish-jira-branch
description: Publish the current Jira branch and create a consistently formatted pull request after explicit approval. Use when the user asks to publish a branch or worktree, publish this worktree, push and open a PR, or says “Publish”.
---

# Publish a Jira Branch and Open a Pull Request

## Workflow

1. Read the current branch with `git branch --show-current`. Extract a Jira key matching `[A-Z][A-Z0-9]+-[0-9]+`. Stop and ask if none or more than one key appears.
2. Fetch the matching Jira issue. Use the Jira search tool first; then use `getJiraIssue` to get its summary and issue type.
3. Inspect origin branches, prioritizing names with the same Jira project and nearby issue keys. Classify the local convention before proposing a name:
   - `feature/` is the usual prefix for Story, Task, and implementation work.
   - `bugfix/` is the usual prefix for Bug tickets. Use `fix/` only if comparable recent branches for the same work area clearly use it.
   - Use `hotfix/`, `chore/`, `refactor/`, `techspike/`, or `release/` only when the Jira issue or branch context explicitly supports that category.
   - Preserve the dominant `PREFIX/PROJECT-123-summary` layout. Use hyphens in the summary, but tolerate existing underscores in older remote branches.
4. Build a short, descriptive slug from the Jira summary:
   - Remove leading sprint/module/task markers such as `[S63]`, `[PC]`, `[01]`, and separator punctuation.
   - Keep the meaningful action and subject; drop filler and repeated words.
   - Use lower-case kebab case and avoid unnecessary length.
5. Resolve the PR base branch with `gh repo view --json defaultBranchRef`; use its `defaultBranchRef.name` rather than assuming `develop`.
   - Run local Git checks, Jira lookups, and GitHub API calls as independent commands (or independent tool calls). Do not chain them with `&&`: a network/API failure must not obscure successful local inspection or prevent its output from being reported.
   - If a GitHub or Jira request fails because network access is sandboxed, retry it through the approved network path. If it still fails, report the unavailable metadata and ask for direction; do not treat the branch inspection as failed.
6. Rename the current local branch with `git branch -m PREFIX/PROJECT-123-slug`.
   - If shared Git metadata is outside the writable worktree, request the required permission rather than modifying files directly.
7. Confirm the resulting local branch with `git branch --show-current`.
8. Refresh and compare against the remote base branch before preparing the PR: run `git fetch origin BASE_BRANCH`, then inspect `git status --short` and clearly identify any uncommitted changes; they are not included by the push. Inspect the unpushed diff and commits against `origin/BASE_BRANCH` (not the local base branch), and infer exactly one PR label:
   - Use `bug` only when the diff clearly fixes incorrect or broken behavior.
   - Use `enhancement` for new or improved behavior, including when the intent is ambiguous.
   - Do not apply any other labels unless the user explicitly asks for them.
9. Prepare the PR details using the template below:
   - Title: `PROJECT-123: Title content`, where `PROJECT-123` is the Jira key and the title content is a human-readable version of the branch summary (remove hyphens, use sentence case, and do not repeat the Jira key or prefix).
   - Body: retain the template headings and checklist; replace the Ticket link with the matching Jira issue. Keep `Affected areas` and `Screenshots` for the author to complete when applicable.
   - Preserve the body as real multiline Markdown. Write the exact body to a temporary file and pass it with `gh pr create --body-file PR_BODY_FILE` (or `gh pr edit --body-file PR_BODY_FILE`). Do not inject `JSON.stringify(body)`, escaped `\n`, or a serialized JSON string into the shell command; GitHub will render those characters literally.
   - Assignee: the authenticated GitHub user (`--assignee @me`).
   - Reviewer: `binh-nguyenthanh-tpv-clv` (Peace (Binh) Nguyen Thanh TPV). Verify with `gh api users/binh-nguyenthanh-tpv-clv --jq '[.login,.name] | @tsv'` if needed. Do not silently omit the reviewer.

   ```markdown
   ## Ticket

   [PROJECT-123](https://oneline.atlassian.net/browse/PROJECT-123)

   ## Affected areas

       - affected area 1
       - affected area 2

   ## Screenshots

   **some screenshots regarding your implementation**

   ### Thank you for your contribution to the repo. Before submitting this PR, please makes:

   - [ ] Your code builds clean without any errors or warnings
   - [ ] Your code formatted with linter
   - [ ] Naming of method, variables, and class is proper ([Coding standard documentation](https://oneline.atlassian.net/wiki/spaces/BTH/pages/1841561601/APM+Coding+conventions+standards))
   - [ ] Check the code changes impact to common code
   - [ ] All UT passed
   - [ ] Unit tests coverage > 80%
   - [ ] The file name is formatted correctly
   - [ ] Removed all unnecessary logs, debugging code
   - [ ] Credentials or sensitive data must not be logged
   - [ ] No security vulnerabilities ([Security Checklist](https://oneline.atlassian.net/wiki/spaces/BTH/pages/2903081130/PR+Security+Checklist))
   ```
10. Before any external write, show the user the final branch name, base branch, PR title, inferred label, reviewer, assignee, rendered PR body, and any uncommitted changes. Ask for explicit approval to publish and create the PR. Do not push or create/update a PR until the user approves.
11. After approval:
    - Publish the branch with `git push --set-upstream origin BRANCH`.
    - Create the PR with `gh pr create`, supplying the approved base, title, `--body-file PR_BODY_FILE`, `--assignee @me`, `--reviewer PEACH_LOGIN`, and the single approved `--label bug` or `--label enhancement`.
    - Verify the created PR body renders as multiline Markdown. If it contains literal `\n`, immediately repair it with `gh pr edit PR_NUMBER --body-file PR_BODY_FILE` before handing off.
    - Confirm the PR URL, branch, assignee, reviewer request, and label. If PR creation succeeds but a post-creation assignment fails, report that partial outcome clearly and continue only with user direction.

## Examples

- `CNPRD-24293` with a Bug titled “System cannot download file to device when clicking directly on the link Download to Device” becomes `bugfix/CNPRD-24293-download-to-device-link`, then a PR titled `CNPRD-24293: Download to device link` labeled `bug`.
- `CNPRD-24216` with an enhancement/Story title becomes `feature/CNPRD-24216-update-service-scope-display`, then a PR titled `CNPRD-24216: Update service scope display` labeled `enhancement`.
