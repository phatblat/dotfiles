---
description: Conventions for GitHub Actions workflows and action definitions
paths:
  - ".github/workflows/*.yml"
  - ".github/workflows/*.yaml"
  - ".github/actions/**/action.yml"
  - ".github/actions/**/action.yaml"
---

# GitHub Actions Conventions

## Action Version Pinning

Pinning rules differ by action origin:

| Origin | Rule | Example |
|--------|------|---------|
| **External** (outside the consuming repo's org) | Pin to full commit SHA with tag comment | `actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2` |
| **Same-org** (same GitHub org as the consuming repo) | Floating major tag is fine | `my-org/action@v1` |
| **Local** (same repo, `./path/`) | No pinning needed | `./path/to/action` |

### External Actions — SHA Pinning

```yaml
- uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
```

**Why:** Tag-only pinning (e.g., `@v4`) is vulnerable to supply chain attacks — tags are mutable and can be force-pushed to point at malicious commits. SHA pinning guarantees reproducibility and integrity.

Format:
```
uses: <owner>/<repo>@<full-40-char-sha> # <tag>
```

- The SHA is the pinned version (immutable)
- The trailing comment is the human-readable tag (for update tracking)
- Tools like Dependabot and Renovate understand this format and will update both

### Same-Org Actions — Floating Tags

Actions published within the same GitHub org as the consuming repo may use floating major tags:

```yaml
- uses: my-org/action@v1
```

This is intentional — the org controls both repos and can coordinate releases. SHA pinning same-org actions provides little security benefit while breaking the normal floating-tag release model.

### Pin Exceptions

For cases that don't fit the table above, mark with an inline comment:

```yaml
uses: my-org/action@main  # gha-pin-allow: linked-branch
```

Valid exception reasons:

| Reason          | When to use                                               |
|-----------------|-----------------------------------------------------------|
| `linked-branch` | Cross-repo development where repos are branched in tandem |

Lines using a branch ref (e.g., `@main`) without `# gha-pin-allow:` should be flagged, regardless of origin.

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

## Node.js Runtime Requirements

GitHub Actions is deprecating Node.js 20 runners. As of June 2, 2026, actions are forced to run on Node.js 24. **Only use action versions that declare `using: node24` (or higher) in their action.yml.**

Minimum versions for common actions (Node.js 24 compatible):

| Action                     | Minimum | Current | SHA |
|----------------------------|---------|---------|-----|
| `actions/checkout`         | v6      | v6.0.2  | `de0fac2e4500dabe0009e67214ff5f5447ce83dd` |
| `actions/setup-node`       | v6      | v6.4.0  | `48b55a011bda9f5d6aeb4c2d9c7362e8dae4041e` |
| `actions/cache`            | v5      | v5.0.5  | `27d5ce7f107fe9357f9df03efb73ab90386fccae` |
| `actions/upload-artifact`  | v7      | v7.0.1  | `043fb46d1a93c77aae656e7c1c64a875d1fc6a0a` |
| `actions/download-artifact`| v8      | v8.0.1  | `3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c` |

When encountering an action pinned to a version below these minimums, update it. When adding a new third-party action, verify its `action.yml` declares `using: node24` or higher.

## Common Gotchas

### `~` is NOT expanded in `with:` blocks

Action inputs (`with:`) are passed as plain strings — the shell never interprets them, so both `~` and `$HOME` stay literal and cause "binary not found" or "path not found" errors.

**Broken:**
```yaml
- uses: some/action@v1
  with:
    path: ~/.my-tool/bin    # ~ stays literal
    path: $HOME/.my-tool/bin  # $HOME also stays literal
```

**Simple fix:** Use `${{ env.HOME }}` (GitHub Actions expression syntax) — this is evaluated by the runner, not the shell:

```yaml
- uses: some/action@v1
  with:
    path: ${{ env.HOME }}/.my-tool/bin
```

**Multi-step fix:** When the path is complex or reused across several steps, resolve it once via outputs:

```yaml
- id: resolve-path
  run: echo "dir=$HOME/.my-tool/bin" >> "$GITHUB_OUTPUT"

- uses: some/action@v1
  with:
    path: ${{ steps.resolve-path.outputs.dir }}
```

This applies to `actions/cache` `path:`, `path_to_*` inputs, and any `with:` value that expects a filesystem path.

## Workflow Best Practices

- Use `permissions:` at the workflow level to restrict token scope (principle of least privilege)
- Prefer `pull_request` over `pull_request_target` unless secrets are needed for fork PRs
- Set `timeout-minutes` on jobs to prevent runaway billing
- Use `concurrency` groups to cancel redundant runs on the same branch
