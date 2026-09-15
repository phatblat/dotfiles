---
name: "pr-update-desc"
description: "Update the PR description for the current branch"
---

# pr-update-desc

Use this skill when the user asks to run the migrated command `pr-update-desc` or invokes `$pr-update-desc`.

## Command Template

# Update PR Description

Regenerate and update the GitHub PR description for the current branch based on all commits in the PR.

## Instructions

### 0. Load PR Style

Invoke the `pr-style` skill to load formatting conventions for the PR body. If the target repo has its own PR template (detected in Step 3), the repo template **replaces** the pr-style default body, while pr-style still governs title format (unless the template's frontmatter specifies one), labels, assignment, and draft policy.

### 1. Gather Context

Run a single combined command:

```bash
remote=$(git remote | head -1)
branch=$(git branch --show-current)
default_branch=$(git symbolic-ref refs/remotes/${remote}/HEAD 2>/dev/null | sed "s|refs/remotes/${remote}/||" || echo "main")
echo "remote=${remote} branch=${branch} default=${default_branch}"
```

### 2. Find the PR

```bash
gh pr view --json number,url,title,body --jq '"\(.number)|\(.title)|\(.url)"'
```

If no PR exists for the current branch, stop and report: "No open PR found for branch `${branch}`."

### 3. Collect Commit History

Get all commits on this branch since it diverged from the default branch:

```bash
git log --oneline ${default_branch}..HEAD
```

Also get the full diff stat for a high-level summary of what changed:

```bash
git diff --stat ${default_branch}...HEAD
```

These outputs are used when filling in the selected PR template (or the pr-style default body if no repo template is found).

#### 3a. Detect the repo's PR template

Read-only lookup, run in parallel with the diff inspection. Check GitHub's template locations in order:

- Single template: `pull_request_template.md` (or `.txt`) in the repo root, `docs/`, or `.github/`
- Multiple templates: every `*.md` in `.github/PULL_REQUEST_TEMPLATE/`
- **Picker file**: a root/`.github`/`docs/` single template whose content is only links of the form `?quick_pull=1&template=<file>` — it routes to the `.github/PULL_REQUEST_TEMPLATE/` files; treat it as the multiple-templates case and never use the picker itself as the body format.

Read every candidate template found (full content, including any YAML frontmatter). Also read repo-local `AGENTS.md` (or `CLAUDE.md` / `.cursorrules` if present) and note any PR-template or PR-format guidance it carries. Do not select a template yet — selection happens at body generation (Step 4), because the commit log can flip the choice.

### 4. Generate PR Description

#### 4a. Select the template

Apply in order (first match wins):

1. Repo-local `AGENTS.md` explicitly mandates a template or required PR format → follow that; an explicit mandate (e.g. "always use release.md", required extra sections, sign-off blocks) overrides the rules below.
2. Exactly one template found → use it.
3. Version-only bump in the branch log (single commit, message matches a version-bump pattern like `bump version` / `chore(release): v<semver>` / `version <semver>`) and a release-named template exists (e.g. `release.md`) → use the release template.
4. Otherwise prefer a feature/change-named template (e.g. `feature.md`, `change.md`, `bug_fix.md` matching the change type from commit prefixes) when one exists.
5. Still ambiguous (several plausible non-release templates) → ask the user which template applies, one question with the candidate names, before drafting.
6. No template found and `AGENTS.md` carries no PR-format guidance → record "no template found"; the pr-style default body applies, with any `AGENTS.md` PR conventions (required sections, trailers, sign-offs) layered on as extra requirements.

#### 4b. Apply the template

- If a template was selected: use its body structure **instead of** the pr-style default body. Fill every template section with real content derived from the Step 3 log/diff; a template section left as an unfilled placeholder or TODO is a blocker — report it rather than posting an unfilled template.
- Frontmatter handling: if the template begins with YAML frontmatter (`---` fenced), strip it from the PR body. For an existing PR, `gh pr edit --body` only rewrites the body, so do **not** change the PR title or existing labels based on frontmatter; still record the template source in the report. If labels must be updated, direct the user to `$pr-create`/`gh pr edit` options rather than inventing label edits here.
- If no template: generate the body per pr-style, plus any `AGENTS.md` conventions per 4a rule 6.

### 5. Update the PR

```bash
gh pr edit --body "<generated description>"
```

Use a HEREDOC to pass the body to preserve formatting:

```bash
gh pr edit --body "$(cat <<'EOF'
<generated description>
EOF
)"
```

### 6. Report Result

Output:

```
✅ Updated PR #<number> description
<pr_url>
Template: <name or default pr-style body>
```
