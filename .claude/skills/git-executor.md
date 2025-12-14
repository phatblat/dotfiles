# Git Executor Skill

Execute git commands and return structured results with status codes and output.

## Capability

Executes git version control commands and returns:
- **Status codes** — Success/failure of operation
- **Output** — Command stdout and stderr
- **Duration** — Execution time
- **Warnings** — Potential issues or safety concerns

Supports core git operations: commit, branch, checkout, merge, rebase, push, pull, fetch, log, diff, status, stash, reset, and more.

## How to Use This Skill

### Input
```
{
  "action": "execute",
  "command": "commit",                      // Git command (no 'git' prefix)
  "args": ["-m", "Fix authentication bug"], // Command arguments
  "directory": ".",                         // Working directory (default: current)
  "timeout": 30000,                         // Timeout in milliseconds (default: 120000)
  "dryRun": false                           // Show what would be done, don't execute
}
```

### Output

Returns execution result:
```
{
  "status": "success",  // success|error|timeout
  "command": "git commit -m 'Fix authentication bug'",
  "exitCode": 0,
  "stdout": "[main abc1234] Fix authentication bug\n 1 file changed, 5 insertions(+), 2 deletions(-)\n",
  "stderr": "",
  "duration": "0.3s",
  "warnings": [],
  "changes": {
    "filesChanged": 1,
    "insertions": 5,
    "deletions": 2,
    "newCommit": "abc1234567890"
  },
  "safety": {
    "isSafe": true,
    "checks": [
      {
        "type": "branch_protection",
        "result": "ok",
        "message": "Commit is not on main/master"
      }
    ]
  }
}
```

## Supported Commands

### Information
- `status` — Show working tree status
- `log` — View commit history with options
- `diff` — Show differences
- `branch` — List, create, or manage branches
- `tag` — Show, create, or manage tags
- `show` — Show commit details

### Branching
- `branch [name]` — Create new branch
- `checkout [branch]` — Switch branches
- `checkout -b [branch]` — Create and switch to branch
- `switch [branch]` — Switch to branch (newer syntax)

### Staging & Committing
- `add [files]` — Stage changes
- `reset [files]` — Unstage changes
- `commit -m [message]` — Commit with message
- `commit --amend` — Amend last commit

### Syncing
- `fetch [remote]` — Fetch from remote
- `pull [remote] [branch]` — Pull changes
- `push [remote] [branch]` — Push changes
- `push --force-with-lease` — Force push safely

### History Manipulation
- `rebase [branch]` — Rebase onto branch
- `merge [branch]` — Merge branch
- `cherry-pick [commit]` — Pick specific commit
- `revert [commit]` — Revert commit

### Cleanup
- `stash` — Stash changes
- `stash pop` — Restore stashed changes
- `clean -fd` — Remove untracked files
- `reset --hard [commit]` — Hard reset (destructive!)

## Protocol

1. **Receive git command** with arguments and options
2. **Check command safety** (prevent direct main/master commits, etc.)
3. **Execute git command** with timeout protection
4. **Capture output** (stdout, stderr, exit code)
5. **Parse results** for useful metadata
6. **Return structured report** with status and warnings
7. **Do NOT interpret** results (agent's responsibility)

## Constraints

This skill **does not**:
- Modify commit history on shared branches
- Push to main/master directly (prevented by safety checks)
- Force-push without `--force-with-lease`
- Perform interactive operations (rebase -i, add -i)
- Configure git (use git config commands separately)
- Handle merge conflicts (returns output for agent to resolve)
- Execute arbitrary shell commands (git only)

## Safety Checks

The skill validates:

| Check | Prevents |
|-------|----------|
| Branch protection | Commits/pushes to main/master |
| Force push safety | Unsafe `--force` (requires `--force-with-lease`) |
| Destructive operations | Hard resets without explicit warning |
| Hook bypass | Commits with --no-verify without authorization |
| Authentication | Operations requiring credentials |

## Example Invocations

### Create Feature Branch
```
[invoke git-executor]
input: {
  "action": "execute",
  "command": "checkout",
  "args": ["-b", "feature/new-auth"]
}

Output:
{
  "status": "success",
  "exitCode": 0,
  "stdout": "Switched to a new branch 'feature/new-auth'\n",
  "changes": {
    "newBranch": "feature/new-auth",
    "baseBranch": "main"
  }
}
```

### Commit Changes
```
[invoke git-executor]
input: {
  "action": "execute",
  "command": "commit",
  "args": ["-m", "feat: add OAuth2 support"]
}

Output:
{
  "status": "success",
  "exitCode": 0,
  "stdout": "[feature/new-auth a1b2c3d] feat: add OAuth2 support\n 2 files changed, 45 insertions(+), 3 deletions(-)\n",
  "changes": {
    "filesChanged": 2,
    "insertions": 45,
    "deletions": 3,
    "newCommit": "a1b2c3d"
  }
}
```

### View Recent Commits
```
[invoke git-executor]
input: {
  "action": "execute",
  "command": "log",
  "args": ["-5", "--oneline"]
}

Output:
{
  "status": "success",
  "exitCode": 0,
  "stdout": "a1b2c3d feat: add OAuth2\n1f2e3d4 fix: auth error handling\n9z8y7x6 refactor: cleanup\n...",
  "changes": {
    "commitsShown": 5
  }
}
```

### Attempt Direct Main Commit (Blocked)
```
[invoke git-executor]
input: {
  "action": "execute",
  "command": "commit",
  "args": ["-m", "fix"]
}

Output (on main branch):
{
  "status": "error",
  "safety": {
    "isSafe": false,
    "checks": [
      {
        "type": "branch_protection",
        "result": "blocked",
        "message": "Direct commits to main/master are not allowed. Create a feature branch instead."
      }
    ]
  }
}
```

## Error Cases

| Scenario | Response |
|----------|----------|
| Invalid command | `"Unknown git command: [command]. Supported: branch, checkout, commit, etc."` |
| Merge conflict | `"Merge conflict detected. Resolve conflicts manually and stage changes."` |
| Authentication failed | `"Authentication failed. Check credentials and SSH keys."` |
| File not found | `"File not found: [path]"` |
| Already on branch | `"Already on branch '[name]'"` |
| Branch protection | `"Branch '[main]' is protected. Create a feature branch."` |
| Timeout | `"Command timeout: exceeded [timeout]ms limit"` |
| Safety violation | `"Operation blocked by safety check: [reason]"` |

## Git Command Syntax

Commands should be specified without the `git` prefix:

```
CORRECT: command: "commit", args: ["-m", "message"]
CORRECT: command: "checkout", args: ["-b", "feature"]
CORRECT: command: "log", args: ["--oneline", "-10"]
INCORRECT: command: "git commit -m 'message'"
```

## Integration Notes

- **Used by agents**: github-expert, implementor, project-planner
- **Returns structured data**: Command output + parsed metadata
- **Always fresh**: Executes real git commands, no caching
- **Safety-aware**: Prevents dangerous operations (main commits, unsafe force-push)
- **Output-focused**: Returns stdout/stderr for agent interpretation
- **No interpretation**: Agent decides what to do with results
- **Timeout protection**: Prevents hanging on long operations
- **Error-safe**: Returns structured error codes, never crashes
