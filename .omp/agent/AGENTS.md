## Bash tool usage

NEVER prefix shell commands with `cd <path> &&`. The session already starts in the intended working directory (launched with `--allow-home`). To run a command in a different directory, pass the bash tool's `cwd` parameter instead of using `cd`. A `cd` prefix turns the call into a compound command that omp splits and approves part by part, so the `cd` needs its own approval and every call carries an extra, redundant command.
