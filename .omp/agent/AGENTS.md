## Bash tool usage

NEVER prefix shell commands with `cd <path> &&`. The session already starts in the intended working directory (launched with `--allow-home`). To run a command in a different directory, pass the bash tool's `cwd` parameter instead of using `cd`. A `cd` prefix invalidates whitelist approval patterns and forces an approval prompt for every command.
