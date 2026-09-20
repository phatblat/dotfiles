## Bash tool usage

NEVER prefix shell commands with `cd <path> &&`. The session already starts in the intended working directory (launched with `--allow-home`). To run a command in a different directory, pass the bash tool's `cwd` parameter instead of using `cd`. A `cd` prefix invalidates whitelist approval patterns and forces an approval prompt for every command.

## Bash compound commands

Enable per-segment approval for `&&` chains so that multi-command whitelists work without prompting:

```
omp config set bash.allowCompoundCommands true
```

(Disabled by default; `omp://approval-mode.md` §compound.) Once `cd` prefixes are eliminated, `&&` chains of whitelisted commands execute without approval prompts.
