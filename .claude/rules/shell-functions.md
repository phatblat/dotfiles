---
paths:
  - ".config/zsh/**"
  - ".config/fish/**"
  - ".config/nushell/**"
  - ".zshrc"
  - ".bashrc"
  - "docs/functions.md"
---

# Shell Function Conventions

## Shell Priority

1. **Zsh (Primary)** — Functions in `~/.config/zsh/functions/*`
2. **Fish (Secondary)** — Functions in `~/.config/fish/functions/*.fish`
3. **Nushell (Active)** — Functions in `~/.config/nushell/autoload/*.nu`
4. **Bash (Minimal)** — Define in `~/.bashrc`

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

## Required Bookkeeping

After any function change, ALWAYS update `~/docs/functions.md`:
- Add/remove/update the row in the alphabetically-sorted table
- Update checkmarks for which shells implement it (nu, fish, zsh, bash)
- Update Summary statistics if shell counts change

Test the function in the target shell.
