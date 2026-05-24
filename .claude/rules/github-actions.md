---
description: Conventions for GitHub Actions workflows and action definitions
globs:
  - ".github/workflows/*.yml"
  - ".github/workflows/*.yaml"
  - ".github/actions/**/action.yml"
  - ".github/actions/**/action.yaml"
---

# GitHub Actions Conventions

## Action Version Pinning

All external actions MUST be pinned to a full commit SHA with the semantic version tag in a trailing comment:

```yaml
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
```

**Why:** Tag-only pinning (e.g., `@v4`) is vulnerable to supply chain attacks — tags are mutable and can be force-pushed to point at malicious commits. SHA pinning guarantees reproducibility and integrity.

### Format

```
uses: <owner>/<repo>@<full-40-char-sha> # <tag>
```

- The SHA is the pinned version (immutable)
- The trailing comment is the human-readable tag (for update tracking)
- Tools like Dependabot and Renovate understand this format and will update both

### Pin Exceptions

Certain uses may be exempt from SHA pinning. Mark them with an inline comment:

```yaml
uses: my-org/action@main  # gha-pin-allow: linked-branch
```

Valid exception reasons:

| Reason           | When to use                                                  |
|------------------|--------------------------------------------------------------|
| `linked-branch`  | Cross-repo development where repos are branched in tandem    |
| `local`          | Composite actions in the same repo (`./path/to/action`)      |
| `reusable`       | Reusable workflows in the same org during active development |

Lines without `# gha-pin-allow:` that use a branch or tag instead of a SHA should be flagged.

### How to Find the SHA

```bash
gh api repos/{owner}/{repo}/git/ref/tags/{tag} --jq '.object.sha'
```

For annotated tags (most releases), the above returns the tag object — dereference it:

```bash
gh api repos/{owner}/{repo}/git/tags/{tag-sha} --jq '.object.sha'
```

Or use `git ls-remote`:

```bash
git ls-remote https://github.com/{owner}/{repo}.git refs/tags/{tag}
```

## Workflow Best Practices

- Use `permissions:` at the workflow level to restrict token scope (principle of least privilege)
- Prefer `pull_request` over `pull_request_target` unless secrets are needed for fork PRs
- Set `timeout-minutes` on jobs to prevent runaway billing
- Use `concurrency` groups to cancel redundant runs on the same branch
