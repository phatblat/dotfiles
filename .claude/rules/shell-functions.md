---
paths:
  - ".config/zsh/**"
  - ".config/nushell/**"
  - ".zshrc"
  - ".bashrc"
  - "docs/functions.md"
---

# Shell Function Conventions

1. **Nushell (Primary)** — Functions in `~/.config/nushell/autoload/*.nu`
2. **Zsh (Fallback)** — Functions in `~/.config/zsh/functions/*`
3. **Bash (Minimal)** — Define in `~/.bashrc`

## Zsh Autoload Pattern (CRITICAL)

- Create standalone files in `~/.config/zsh/functions/` — never define in `.zshrc`
- File content IS the function body directly — NOT wrapped in `function name() { }`
- Start with `#!/usr/bin/env zsh` shebang
- Add comment: `# function_name - Description`
- No execute permissions needed

Example:
```zsh
#!/usr/bin/env zsh

# aa - Add all modified tracked files to git staging area
git add --update "$@"
```

## Auto-formatting

Zsh functions are auto-formatted by shfmt/shellharden via `just format-shell`; files using zsh-only syntax are excluded via Justfile variables.

## Required Bookkeeping

- Add/remove/update the row in the alphabetically-sorted table
- Update checkmarks for which shells implement it (nu, zsh, bash)
- Update Summary statistics if shell counts change

Test the function in the target shell.
