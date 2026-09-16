---
name: pr-create
description: Create or update a GitHub pull request for the current branch. Use when the user invokes `$pr-create`, asks to create/open a PR, or wants the current branch pushed and described as a draft PR.
---

# pr-create

Create a GitHub PR for the current branch. If a PR already exists, use `$pr-update-desc` to refresh its description instead.

## Workflow

### 0. Load PR style

Use the `pr-style` skill for title format, body template, labels, assignment, and draft policy. Follow those rules for the PR title, body, and label handling. If the target repo has its own PR template (detected in Step 4), the repo template **replaces** the pr-style default body, while pr-style still governs title format (unless the template's frontmatter specifies one), labels, assignment, and draft policy.

### 1. Gather context

Run:

```bash
remote=$(git remote | head -1)
branch=$(git branch --show-current)
default_branch=$(git symbolic-ref refs/remotes/${remote}/HEAD 2>/dev/null | sed "s|refs/remotes/${remote}/||" || echo "main")
echo "remote=${remote} branch=${branch} default=${default_branch}"
```

If `branch` equals `default_branch`, stop and report:

```text
Cannot create a PR from the default branch (`<default_branch>`).
```

### 2. Check for an existing PR

Run:

```bash
gh pr list --head "${branch}" --state open --json number,url,title --jq '.[0] | "\(.number)|\(.title)|\(.url)"'
```

- If a PR exists, report `PR #<number> already exists`, use `$pr-update-desc` to update the description, then stop.
- If no PR exists, continue.

### 3. Ensure the branch is pushed

Check whether the remote branch exists:

```bash
git ls-remote --heads "${remote}" "${branch}"
```

If no remote branch exists, push with an explicit refspec:

```bash
git push -u "${remote}" "${branch}:${branch}"
```

If the remote branch exists, push the current local branch to it:

```bash
git push "${remote}" "${branch}:${branch}"
```

### 4. Collect PR source material

Get branch commits:

```bash
git log --oneline "${default_branch}..HEAD"
```

Get the high-level diff:

```bash
git diff --stat "${default_branch}...HEAD"
```

These outputs are used when filling in the selected PR template (or the pr-style default body if no repo template is found).

#### 4a. Detect the repo's PR template

Read-only lookup, run in parallel with the diff inspection. Check GitHub's template locations in order:

- Single template: `pull_request_template.md` (or `.txt`) in the repo root, `docs/`, or `.github/`
- Multiple templates: every `*.md` in `.github/PULL_REQUEST_TEMPLATE/`
- **Picker file**: a root/`.github`/`docs/` single template whose content is only links of the form `?quick_pull=1&template=<file>` — it routes to the `.github/PULL_REQUEST_TEMPLATE/` files; treat it as the multiple-templates case and never use the picker itself as the body format.

Read every candidate template found (full content, including any YAML frontmatter). Also read repo-local `AGENTS.md` (or `CLAUDE.md` / `.cursorrules` if present) and note any PR-template or PR-format guidance it carries. Do not select a template yet — selection happens at body generation (Step 6), because the commit log can flip the choice.

### 5. Detect labels

Map conventional commit prefixes in the branch log using the `pr-style` label table. Validate candidate labels against the repo:

```bash
gh label list --json name --jq '.[].name'
```

Apply only labels that exist. If no valid labels exist, omit label flags.

### 6. Create the draft PR

#### 6a. Select the template

Apply in order (first match wins):

1. Repo-local `AGENTS.md` explicitly mandates a template or required PR format → follow that; an explicit mandate (e.g. "always use release.md", required extra sections, sign-off blocks) overrides the rules below.
2. Exactly one template found → use it.
3. Version-only bump in the branch log (single commit, message matches a version-bump pattern like `bump version` / `chore(release): v<semver>` / `version <semver>`) and a release-named template exists (e.g. `release.md`) → use the release template.
4. Otherwise prefer a feature/change-named template (e.g. `feature.md`, `change.md`, `bug_fix.md` matching the change type from commit prefixes) when one exists.
5. Still ambiguous (several plausible non-release templates) → ask the user which template applies, one question with the candidate names, before drafting.
6. No template found and `AGENTS.md` carries no PR-format guidance → record "no template found"; the pr-style default body applies, with any `AGENTS.md` PR conventions (required sections, trailers, sign-offs) layered on as extra requirements.

#### 6b. Apply the template

- If a template was selected: use its body structure **instead of** the pr-style default body. Fill every template section with real content derived from the Step 4 log/diff; a template section left as an unfilled placeholder or TODO is a blocker — report it rather than posting an unfilled template.
- Frontmatter handling: if the template begins with YAML frontmatter (`---` fenced), strip it from the PR body. Honor `labels:` by merging those labels into the Step 5 validated-label set (still drop any that fail `gh label list` validation). Honor `title:` as the title format/prefix, overriding the pr-style title format for this PR. Ignore other frontmatter keys (`assignees:`, `draft:`, etc.) — pr-style's `--draft --assignee @me` flags remain authoritative.
- If no template: generate the body per pr-style, plus any `AGENTS.md` conventions per 6a rule 6.

Create a draft PR assigned to the current GitHub user:

```bash
gh pr create --draft --assignee @me --title "<title>" --body "$(cat <<'EOF'
<generated description>
EOF
)"
```

If valid labels were detected, include them with repeated `--label "<label>"` flags.

### 7. Report result

Output:

```text
Created PR #<number> (draft)
<pr_url>
Labels: <applied labels or none>
Assigned: @me
Template: <name or default pr-style body>
```
