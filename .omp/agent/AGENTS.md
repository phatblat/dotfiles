## Bash tool usage

NEVER prefix shell commands with `cd <path> &&`. The session already starts in the intended working directory (launched with `--allow-home`). To run a command in a different directory, pass the bash tool's `cwd` parameter instead of using `cd`. A `cd` prefix turns the call into a compound command that omp splits and approves part by part, so the `cd` needs its own approval and every call carries an extra, redundant command.

The user's interactive shell is nushell. ALWAYS present commands intended for the user to run in nushell syntax, never POSIX/bash syntax. Key differences: use `;` or newlines instead of `&&`/`||` (or `;` with `$env.LAST_EXIT_CODE` checks), `let x = ...` instead of `x=...`, `$env.FOO` to read environment variables, `FOO=bar cmd` is not supported (use `with-env { cmd }`), `str join`/`each`/`where` pipelines instead of `xargs`/`awk`/`sed` idioms, and `^cmd` to force running an external when a nu builtin shadows it. The bash tool itself still runs bash; this rule applies to commands shown to the user in chat.

## Prose formatting in files and PRs

NEVER hard-wrap prose when writing markdown files, documentation, ADRs, PR descriptions, commit bodies, or any content meant for humans to read in rendered form. Write each paragraph (and each list item) as a single logical line and let the reader's editor/renderer soft-wrap it. Do not insert line breaks mid-sentence to fit a terminal or TUI width. Hard-wrapping is acceptable ONLY where the file's existing style already uses it consistently, or where the format requires it (e.g. fixed-width plain-text files).
