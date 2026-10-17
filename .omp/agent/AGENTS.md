## Bash tool usage

NEVER prefix shell commands with `cd <path> &&`. The session already starts in the intended working directory (launched with `--allow-home`). To run a command in a different directory, pass the bash tool's `cwd` parameter instead of using `cd`. A `cd` prefix changes the leading word that approval patterns and the shared guard match on, and hides the working directory from the guard's `--cwd` checks.
