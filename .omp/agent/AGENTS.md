## Bash tool usage

The user's interactive shell is nushell. ALWAYS present commands intended for the user to run in nushell syntax, never POSIX/bash syntax. Key differences: use `;` or newlines instead of `&&`/`||` (or `;` with `$env.LAST_EXIT_CODE` checks), `let x = ...` instead of `x=...`, `$env.FOO` to read environment variables, `FOO=bar cmd` is not supported (use `with-env { cmd }`), `str join`/`each`/`where` pipelines instead of `xargs`/`awk`/`sed` idioms, and `^cmd` to force running an external when a nu builtin shadows it. The bash tool itself still runs bash; this rule applies to commands shown to the user in chat.

## Response language and audience

Always respond in English, regardless of the language the user writes in. Code, code comments, and command output are also in English.

Write for a senior software engineer: assume deep fluency with software design, tooling, and industry terminology. Skip definitions and basic explanations, and spend words on decisions, tradeoffs, risks, and non-obvious details. This overrides the built-in "assume reader technical" audience rule.

## Prose formatting in files and PRs

NEVER hard-wrap prose when writing markdown files, documentation, ADRs, PR descriptions, commit bodies, or any content meant for humans to read in rendered form. Write each paragraph (and each list item) as a single logical line and let the reader's editor/renderer soft-wrap it. Do not insert line breaks mid-sentence to fit a terminal or TUI width. Hard-wrapping is acceptable ONLY where the file's existing style already uses it consistently, or where the format requires it (e.g. fixed-width plain-text files).

## Temp files

`/tmp` is not shared between the file tools and the shell: `write`/`read`/`edit` resolve `/tmp` to its real path `/private/tmp` (macOS symlinks `/tmp` → `private/tmp`), while the bash tool's shell honors `TMPDIR` (`/var/folders/.../T/`), so a file created by one side is invisible to the other. NEVER pass a `/tmp/...` path to `write`, `read`, or `edit` for anything the shell must also see, and never assume a shell-created temp file is reachable through `/tmp`.

For temp files shared between tools and shell: create the file in the shell first (`mktemp`, or `> "$TMPDIR/name"`), capture the absolute path the shell prints, and pass that exact path to `write`/`read`/`edit`. Prefer a workspace-local temp dir when the file is project-related.
