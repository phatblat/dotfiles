## Bash tool usage

NEVER prefix shell commands with `cd <path> &&`. The session already starts in the intended working directory. To run a command somewhere else, pass the bash tool's `cwd` parameter. When `cwd` is omitted, omp strips a leading `cd <path> &&` into `cwd` anyway, so the prefix only adds tokens.
