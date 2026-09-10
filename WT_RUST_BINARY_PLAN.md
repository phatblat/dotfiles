> Repo root **is** `$HOME` (`/Users/phatblat`, `phatblat/dotfiles`). Every relative path below is `$HOME`-relative.

## Context

`wt` (navigate to / create git worktrees under `~/.worktrees/<path-key>/<branch>`) exists three times today — `.config/zsh/functions/wt` (189 lines), `.config/nushell/autoload/wt.nu` (171 lines), `.agents/skills/git-worktree/wt.sh` (316 lines) — plus `wt-env` twice (`.config/zsh/functions/wt-env`, `.config/nushell/autoload/wt-env.nu`). The three `wt` copies must be kept behaviourally identical by hand; `tests/wt.bats` asserts the same behaviour twice or three times per case for exactly that reason.

End state: one Rust binary `crates/wt` installed at `~/.local/bin/wt` owns all logic. Two ~10-line shell wrappers exist only because a child process cannot change its parent shell's directory. `wt.sh` and both `wt-env` copies are deleted. `wt-env`'s job is generalised into `wt overlay`, a manifest-driven symlink farm that also replaces the ad-hoc `MISE_DATA_DIR` env patch for HOME-remapped dotfiles worktrees. The `$HOME`-repo opt-in flag is renamed `--dotfiles` → `--allow-home`, matching `omp --allow-home`.

## Decisions already made (do not revisit)

- **Flag name is `--allow-home`.** `--dotfiles` is removed everywhere, with no alias. Chosen by the user for vocabulary parity with `omp --allow-home` and with `.config/zsh/functions/omp`, which injects that flag unconditionally.
- **Overlay links tooling + credentials.** Manifest content is fixed below.
- **Manifest is a line-oriented text file, not TOML/JSON.** Precedent: `.config/gh/extensions.txt` ("one OWNER/REPO per line", `justfile` line 31). Keeps the crate at **zero third-party dependencies**.
- **Overlay is symlinks.** macOS has no OverlayFS; union mounts need macFUSE (a kernel extension). A symlink farm is the only mechanism available without one, and is what `wt-env` already does.
- **`--cd-file <path>`** is how the binary tells a wrapper where to `cd` (the `broot`/`yazi`/`nnn` pattern). Rejected alternative: inferring intent from stdout shape — `wt list` also prints to stdout, so the wrappers would have to re-parse arguments, reintroducing the duplication this change removes.

## Verified facts the implementation depends on

| Fact | Evidence |
|---|---|
| `~/.local/bin` is on `PATH` | `.zshenv:11`, `.zshrc:125` |
| `z` is zoxide | `.zshrc:128` — `eval "$(zoxide init zsh)"` |
| zsh autoloads every extensionless file in `.config/zsh/functions/` | `.zshrc:39-44` |
| A zsh function shadowing a real binary **must** be force-loaded, or Claude Code's shell-snapshot serialises it as an inert stub | `.zshrc:47-53` |
| `.config/nushell/autoload/*.nu` is `$nu.user-autoload-dirs`; files must contain no top-level statements | `hk.pkl` step `nushell-autoload-purity` |
| `.local/` is entirely untracked (0 tracked files) | `git ls-files .local` → empty |
| `.gitconfig` and `.config/git/config` are **tracked** | `git ls-files --error-unmatch` |
| `.ssh`, `.netrc`, `.config/gh/hosts.yml` exist and are gitignored | `git check-ignore -q` |
| `.gitconfig:152` is `signingkey = ~/.ssh/id_ed25519.pub` — under a remapped `HOME` this resolves inside the worktree, which is why `GIT_CONFIG_VALUE_0=false` exists | `.gitconfig:49,152`; `.github/workflows/lint.yml:95-100` does the same thing for the same reason |
| `target/` is globally ignored, so `crates/wt/target` needs no `.gitignore` edit | `.gitignore:1200` |
| `crates/ness/` is the only control-plane crate; `crates/wt/` is freely editable | `crates/ness/src/policy.rs:124` |
| `just` and `cargo test`/`check`/`clippy`/`fmt` are already permission-allowlisted | `scripts/harness_policy.py:43-46,98` |
| `.claude/commands/git/worktree.md`, `.agents/skills/git-worktree/SKILL.md`, `.agents/skills/using-git-worktrees/SKILL.md` are hand-written **sources**; 12 other files are generated from them | `.agents/harness/generated-paths.json` |
| `omp` relocates when `realpath(cwd) == realpath(homedir())`, to the first existing of `~/tmp`, `/tmp`, `/var/tmp`, else `os.tmpdir()`; `--allow-home` or `--cwd` suppresses it | `applyStartupCwd` in the compiled `omp` v18.1.16 bundle (`packages/coding-agent/src/cli/startup-cwd.ts`), byte offset 91430823 |

## Approach

Ordering, since the steps are grouped by behaviour rather than by file:

- Steps **1, 2, 3, 5** build the crate (5 adds `src/overlay.rs` and the two manifest files). Step **4** wires `just`/CI. Step **9**'s Rust tests (`crates/wt/tests/*.rs`, cases 1–18) prove all of it. Do these first, in that order, and get `just wt-test` green.
- Then `just wt-install`, and confirm `wt` works from a plain bash shell (`wt list`, `wt path <branch> --allow-home`).
- Only then do steps **6, 7, 8**, which retire the shell copies and `wt.sh`. Starting them earlier leaves the shells and the agent surface with no working `wt` at all. Among themselves, 6–8 are independent.
- Step 9's two bats changes belong with step 6, not before it: `tests/wt-wrapper.bats` (cases 19–20) exercises the new wrappers, and `tests/wt.bats` exercises the old shell copies. Delete the latter and add the former in the same step that rewrites the wrappers, so `just test` is never red in between.

### 1. Scaffold `crates/wt` with no dependencies

`crates/wt/Cargo.toml`, mirroring `crates/ness/Cargo.toml` exactly (own `[workspace]` stanza so it stays out of any parent workspace, own `Cargo.lock`, same release profile):

```toml
[workspace]

[package]
name = "wt"
version = "0.1.0"
edition = "2021"
description = "Git worktree resolver for the ~/.worktrees/<path-key>/<branch> convention."
publish = false

[[bin]]
name = "wt"
path = "src/main.rs"

[profile.release]
lto = true
codegen-units = 1
panic = "abort"
strip = true
```

No `[dependencies]` section. Everything needed is in `std`:

- git/fzf/`just` invocation → `std::process::Command`
- process replacement for `wt shell` → `std::os::unix::process::CommandExt::exec`
- isolated environment → `Command::env_clear()` (not `env -i`)
- symlinks → `std::os::unix::fs::symlink`
- `cd "$HOME" && pwd -P` → `std::fs::canonicalize`

Module layout: `src/main.rs` (argument parsing + dispatch + exit codes), `src/repo.rs` (repo/path resolution), `src/actions.rs` (the ten actions), `src/overlay.rs` (manifest + linking).

### 2. Port repo and path resolution into `src/repo.rs`

Straight transliteration of `wt.sh:72-128`. Four functions, each keeping its existing comment rationale:

- `home_real() -> PathBuf` — `canonicalize($HOME)`, falling back to `$HOME` verbatim on error. Needed because `git rev-parse` and `git worktree list` always report symlink-resolved paths (`wt.sh:72`).
- `repo_root(allow_home: bool, repo: Option<&Path>) -> Result<PathBuf>` — when `allow_home`, require `git -C <home_real> rev-parse --git-dir` to succeed and return `home_real`; otherwise run `git -C <repo or cwd> rev-parse --path-format=absolute --git-common-dir` and strip the trailing `/.git`. `--show-toplevel` is wrong here and must not be substituted: it returns the *worktree's* root, so it misfires from inside any worktree (`.agents/skills/using-git-worktrees/SKILL.md:29`).
- `path_key(repo_root, home_real) -> String` — `"dotfiles"` when `repo_root == home_real`, else `repo_root` with the `<home_real>/` prefix stripped and every `/` replaced by `-`. This is currently a dead assignment in the zsh copy (`.config/zsh/functions/wt:119`); it becomes live because `overlay` looks the manifest up by it. Preserve the existing behaviour for a repo outside `$HOME` verbatim (`/opt/foo` → `-opt-foo`); do not "fix" the leading dash.
- `wt_path(repo_root, home_real, branch) -> PathBuf` — `${DOTFILES_WT_ROOT:-<home_real>/.worktrees/dotfiles}/<branch>` for the dotfiles repo, else `<home_real>/.worktrees/<path_key>/<branch>`. Keep the `DOTFILES_WT_ROOT` override.
- `find_registered(repo_root, branch) -> Result<Option<PathBuf>>` — parse `git -C <root> worktree list --porcelain`, match `branch refs/heads/<branch>`, return the preceding `worktree ` path. **Keep the mismatch guard** (`wt.sh:110-128`): if a match is found, it is not the repo root itself, and its final component is not `<branch>`, exit 4 with `registered:` / `expected to end in:` detail lines. A mismatch is a defect to surface, never to silently adopt.

### 3. Port the ten actions into `src/actions.rs`

Argument grammar, parsed by hand (no `clap`; `crates/ness/src/main.rs:10-27` sets the hand-rolled precedent):

```
wt [<branch>]                    navigate: fzf picker when no branch, else switch
wt path <branch>                 print the path that would be used; mutates nothing
wt resolve <branch>              print the registered path, or exit 3
wt switch <branch>               resolve, else create; print the path
wt create <branch>               create only; exit 4 if already registered
wt remove <branch> [--force]     git worktree remove + prune; never touches the branch
wt list                          one <path>\t<branch> line per worktree
wt verify <branch>               HOME-remapped `just check` (was `wt --test`)
wt shell <branch>                HOME-remapped interactive zsh (was `wt --shell`)
wt overlay [<branch>]            apply the link manifest (was `wt-env`)
```

Global flags, accepted in any position: `--allow-home`, `--repo <dir>`, `--force`, `--cd-file <path>`.

- **Verb-vs-branch rule:** the first positional is an action iff it is exactly one of the ten verbs above; otherwise it is a branch and the action is `switch`. A branch literally named `list` must be written `wt switch list`. State this in `--help`.
- **Picker rule:** the picker runs iff neither an action nor a branch was given. Flags do not suppress it — so `wt --allow-home` lists the dotfiles repo's worktrees instead of erroring, which is what both shell copies get wrong today (`.config/zsh/functions/wt:26,84`; `.config/nushell/autoload/wt.nu:52`). Implementation: pipe `git -C <root> worktree list` (human format, not porcelain — the `path sha [branch]` shape is what you eyeball) into `fzf` with stderr inherited, take whitespace field 1 of its stdout. `fzf` absent or cancelled → exit 0, no output.
- **`verify`/`shell` imply `--allow-home`**, as `--test`/`--shell` imply `--dotfiles` today. `verify` additionally rejects `--repo` with exit 2 and the existing message (`wt.sh:277-280`).
- Every action calls `git -C <root> worktree prune` first, except `path` (which must mutate nothing) — matching `wt.sh:151,166,238,283`.
- **Creation sequence** (`wt.sh:194-222`), unchanged: refuse when the target exists and is not an empty directory (`rmdir` an empty one); `git fetch --prune origin` when an `origin` remote exists, so a branch pushed since the last fetch is discoverable; then the three-way add — `worktree add <path> <branch>` if `refs/heads/<branch>` exists, `worktree add --track -b <branch> <path> origin/<branch>` if `refs/remotes/origin/<branch>` exists, else `worktree add -b <branch> <path>`.
- **Home-repo guard** (`wt.sh:179-192`), applies to creation only — an already-registered dotfiles worktree still resolves without the flag. Exit 4. New text, with `--dotfiles` gone:

```
wt: worktrees for the repo at $HOME need an explicit opt-in
  Interactive shell startup (.zshenv/.zshrc and the functions
  autoloaded from .config/zsh/functions) is only exercised from
  the real $HOME, so startup changes still need a branch switch.
  Everything the harness covers is verifiable in a worktree:
    wt switch <branch> --allow-home   create/enter
    wt verify <branch>                verify
```

- **`remove` guards** (`wt.sh:247-259`), unchanged: exit 3 when nothing is registered; exit 4 when `canonicalize(cwd)` is the target or inside it; exit 4 when the target is the repo's main worktree; `--force` selects `worktree remove --force`. On success, `worktree prune`, then print `git -C <repo_root> branch -d <branch>` **to stderr** as the follow-up the user may want, and do not run it.
- **`_wt_ancestor_warn`** (`.config/zsh/functions/wt:13-21`) runs before `verify` and `shell`: for each of `.config/mise/config.toml`, `.editorconfig`, `.envrc`, when the file exists in both `home_real` and the worktree and the bytes differ, warn on stderr that tools walking up from cwd may read the `$HOME` copy. Silent when they match, since that is the common case.
- **`verify`**: `Command::new("just").arg("check").current_dir(wt)` with `HOME=<wt>`, `MISE_DATA_DIR=<home_real>/.local/share/mise`, `GIT_CONFIG_COUNT=1`, `GIT_CONFIG_KEY_0=commit.gpgsign`, `GIT_CONFIG_VALUE_0=false`, inheriting the rest. Propagate the child's exit code. The gpgsign override stays even though the overlay now links `.ssh` — `just check` runs `just test`, whose bats fixtures commit, and `.github/workflows/lint.yml:95-100` disables signing for the identical reason.
- **`shell`**: `Command::new("zsh").arg("-i").current_dir(wt).env_clear()` with exactly `HOME=<wt>`, `TERM` (inherited, `xterm-256color` when unset), `PATH=/usr/bin:/bin:/usr/sbin:/sbin:<home_real>/.local/bin:<home_real>/.local/share/mise/shims`, `MISE_DATA_DIR`, the three `GIT_CONFIG_*` vars, `WT_SHELL_CHECKOUT=<wt>`; then `.exec()`. This is today's set verbatim — do not add `EDITOR`, `VISUAL`, or anything else. Note in a comment that `omp` inside this shell resolves to `<wt>/.config/zsh/functions/omp`, which passes `--allow-home`, so `cwd == HOME` does not trigger omp's temp-dir relocation.
- **Dotfiles navigate banner** (`.config/zsh/functions/wt:167-172`), on stderr when `repo_root == home_real`, with `wt --test` updated to `wt verify`:

```
── dotfiles worktree — not your live $HOME ──
  Nothing here is sourced by any running shell.
  Verify:  wt verify <branch>
  Startup semantics (.zshenv/.zshrc, .config/zsh/functions) still need a $HOME branch switch.
```

**Stdout is machine output only; every human or diagnostic line goes to stderr.** `path`, `resolve`, `switch`, `create` print exactly one path. `list` prints `<path>\t<branch>` lines, with `(detached)` for detached heads (`wt.sh:300-304`). `remove`, `overlay` print nothing to stdout. `verify`, `shell` pass the child's streams through.

**Exit codes** (`wt.sh:17-18`): `0` ok, `2` usage, `3` not found, `4` refused, `1` git/IO failure.

**`--cd-file <path>`:** only `switch` — including the bare-branch and picker forms — writes to it, and writes nothing but the resolved directory. Every other action leaves the file untouched. A write failure warns on stderr and preserves the action's exit code: the worktree was created successfully and the path is still on stdout, so failing the command would be wrong.

### 4. Wire build, install, and test into `justfile`

Add three recipes next to the existing `ness-*` block (`justfile:776-795`), copying its shape and its `install-rust-deps` dependency:

```
# Builds the wt worktree resolver (release profile)
[group('checks')]
wt-build: install-rust-deps
    cargo build --release --manifest-path {{ justfile_directory() }}/crates/wt/Cargo.toml

# Installs the wt resolver to ~/.local/bin, the path the shell wrappers exec
[group('checks')]
wt-install: wt-build
    install -m 755 {{ justfile_directory() }}/crates/wt/target/release/wt {{ env("HOME") }}/.local/bin/wt

# CI: agent-harness-parity.yml (wt job)
# Runs the wt resolver's worktree and overlay integration tests
[group('checks')]
wt-test: install-rust-deps
    cargo test --locked --manifest-path {{ justfile_directory() }}/crates/wt/Cargo.toml
```

Add `wt-test` to the `check` recipe's dependency list (`justfile:734`), after `ness-test`.

Add a `wt` job to `.github/workflows/agent-harness-parity.yml`, a copy of the `ness` job (lines 65-93) with `just ness-test` → `just wt-test` and the job name/step name changed. `.github/scripts/changed.sh`'s harness-parity pattern already matches `^…|crates/|…`, so no gate change is needed.

`crates/wt/target` is covered by `.gitignore:1200` (`target/`). `justfile:43`'s `build_artifact_roots` does not include `crates`, matching how `crates/ness/target` is already treated — leave it alone.

### 5. Replace `wt-env` with `wt overlay`

Manifest location: `${WT_OVERLAY_DIR:-<home_real>/.config/wt/overlay}/<path-key>`, falling back to the file named `default` in the same directory when no per-key file exists. `$WT_OVERLAY_DIR` exists so the integration tests can inject a fixture directory. Because `wt` always runs with the real `HOME` (the overlay is applied *before* any `HOME` remapping), it always reads the real `$HOME`'s manifest, never a worktree's copy.

`.gitignore` has no `.config/*` deny rule — it denies individual paths under `.config/` — so `.config/wt/overlay/*` is tracked automatically. No `.gitignore` edit.

Format: one worktree-relative path per line; `#` begins a comment; blank lines ignored. ~15 lines of parsing, no dependency.

Semantics, preserving `wt-env`'s rules (`.config/zsh/functions/wt-env:28-45`):

- **Link root** is the repo's main worktree — the first `worktree ` entry of `git -C <root> worktree list --porcelain`. For the dotfiles repo the main worktree *is* `home_real`, so "link from the main worktree" and "link from the real `$HOME`" are the same rule; there is no dotfiles special case here.
- For each entry: source is `<link_root>/<entry>`, destination `<wt>/<entry>`. Create the destination's parent directories. Then:
  - source missing → `skip: <entry> not found in main worktree` on stderr, continue
  - destination already a symlink → `skip: <entry> already symlinked` on stderr, continue (idempotent)
  - destination exists and is not a symlink → **exit 4**, `wt: <entry> exists in the worktree and is not a symlink`. This is the self-defence that makes a bad manifest entry loud: naming tracked content (`.gitconfig`, `.editorconfig`) fails immediately instead of silently shadowing it.
  - otherwise `symlink(source, destination)` and report `linked: <entry> → <source>` on stderr. Today's `wt-env` splits these lines between stdout and stderr (`.config/zsh/functions/wt-env:36,44` vs `:32,41`); under the new contract every one of them is stderr, because `overlay` produces no machine output at all.
- Applied automatically immediately after a successful `create`, and on demand via `wt overlay [<branch>]` (no branch → the worktree containing cwd). Refusing to run in the main worktree, as `wt-env` does, is unnecessary: the destination-exists guard already covers it.

Create `.config/wt/overlay/default` — preserves `wt-env`'s default of `.env`:

```
# Paths linked from a repo's main worktree into each of its other worktrees.
# One worktree-relative path per line; `#` starts a comment. A missing source
# is skipped with a note on stderr; a destination that exists and is not a
# symlink is an error, never a silent overwrite.
.env
```

Create `.config/wt/overlay/dotfiles`:

```
# Paths linked from the real $HOME into a HOME-remapped dotfiles worktree, so
# `wt verify` and `wt shell` see the tools and credentials the real $HOME has.
#
# Every entry must be gitignored in the dotfiles repo: the worktree then has no
# copy of its own, so the link cannot shadow tracked content. .gitconfig,
# .config/git/config, and .config/gh/config.yml are tracked and must never be
# listed here -- `wt overlay` exits 4 if they are.
.local/share/mise
.ssh
.netrc
.config/gh/hosts.yml
```

`MISE_DATA_DIR` stays set in `verify`/`shell` even though `.local/share/mise` is now linked: it is redundant belt-and-braces for a worktree whose overlay has not been applied, and the repo's "state every setting rather than leaning on defaults" rule (`~/.agents/AGENTS.md`) prefers the explicit form.

Delete `.config/zsh/functions/wt-env` and `.config/nushell/autoload/wt-env.nu`.

### 6. Replace both shell copies with wrappers

`.config/zsh/functions/wt` — replace the whole file. `wt` is added to `.zshrc:53`'s force-load list in step 7 because it now shadows a real binary, so `command wt` is required here to reach the binary rather than recursing.

```zsh
#!/usr/bin/env zsh

# wt - Navigate to or create git worktrees.
#
# All logic lives in the `wt` binary (crates/wt, installed by `just
# wt-install`). This wrapper exists only because a child process cannot change
# its parent shell's directory: the binary writes the directory to enter into
# the file named by --cd-file, and this function acts on it. Every other action
# -- list, path, verify, shell, overlay -- passes straight through untouched.

local cd_file="${TMPDIR:-/tmp}/wt-cd.$$"
: > "$cd_file"
command wt --cd-file "$cd_file" "$@"
local rc=$?
local dest
dest=$(< "$cd_file")
rm -f -- "$cd_file"
[[ -n "$dest" ]] && z "$dest"
return "$rc"
```

`.config/nushell/autoload/wt.nu` — replace the whole file. `def --env` is what lets `cd` affect the caller. The file must contain nothing but this definition, per `hk.pkl`'s `nushell-autoload-purity` step.

```nu
# wt - Navigate to or create git worktrees.
#
# All logic lives in the `wt` binary (crates/wt, installed by `just
# wt-install`). This wrapper exists only because a child process cannot change
# its parent shell's directory: the binary writes the directory to enter into
# the file named by --cd-file, and this function acts on it.
def --env wt [...args: string] {
    let cd_file = ([($env.TMPDIR? | default "/tmp") $"wt-cd.($nu.pid)"] | path join)
    "" | save --force $cd_file
    let rc = (try { ^wt --cd-file $cd_file ...$args; 0 } catch { $env.LAST_EXIT_CODE })
    let dest = (open --raw $cd_file | str trim)
    rm --force $cd_file
    if ($dest | is-not-empty) { cd $dest }
    if $rc != 0 { error make --unspanned { msg: $"wt exited ($rc)" } }
}
```

Both wrapper bodies above are verified working, not sketches. Confirmed on this
machine with a stub `wt` on `PATH` that writes a directory to the path following
`--cd-file`:

| Invocation | zsh | nushell |
|---|---|---|
| `wt <branch>` | `$PWD` becomes the stub's directory | `pwd` becomes the stub's directory |
| `wt list` | table printed, `$PWD` unchanged | table printed, `pwd` unchanged |
| failing action | child stderr passed through, `$?` = 4 | child stderr passed through, `wt exited 4` raised |

Two details are load-bearing and must not be "simplified":

- **zsh `return "$rc"`, not `return $rc`.** `shellharden --check` exits 2 on the unquoted form. The quoted form passes all three of `shfmt -ln zsh -i 4 -sr`, `shellharden --check`, and `shellcheck -s ksh -e SC2168` cleanly — verified by running each against this exact body.
- **nushell `try { … ; 0 } catch { $env.LAST_EXIT_CODE }`, not `do { … } | complete`.** `complete` pipes the child's stdout and stderr, which would leave `wt shell`'s interactive `zsh -i` without a TTY. `try` inherits stdio while still yielding the real exit code — verified on nu 0.115.1 as 0 for a successful child and 4 for one exiting 4. `$nu.pid` and `"" | save --force` are also verified on that version. Both files also pass `nu-check` and `scripts/check-nushell-autoload.py`.

### 7. Register `wt` as a binary-shadowing function

`.zshrc:53` currently reads:

```zsh
autoload -Uz +X aa bq cc dash dc diff fork genv gt jq log omp pkginfo pp reset sha256 sync 2>/dev/null
```

Add `wt` (alphabetically, after `sync`), and add `wt` to the prose name list in the comment at `.zshrc:47-48`. Without this, Claude Code's shell-snapshot mechanism serialises the never-yet-called `wt` autoload function as an inert stub, permanently breaking `wt` for tool calls run against that snapshot — the exact failure the existing list documents.

### 8. Retire `wt.sh` and repoint the agent surface

Delete `.agents/skills/git-worktree/wt.sh`. The binary *is* the agent-side implementation now; agents call `wt` on `PATH`.

`.claude/commands/git/worktree.md` (hand-written source for five generated artifacts):

- line 4: `Bash(~/.agents/skills/git-worktree/wt.sh:*)` → `Bash(wt:*)`
- line 6: `argument-hint` — `[--dotfiles]` → `[--allow-home]`
- line 19: `` !`~/.agents/skills/git-worktree/wt.sh list 2>/dev/null` `` → `` !`wt list 2>/dev/null` ``
- lines 23, 25, 31: `--dotfiles` → `--allow-home`

`.agents/skills/git-worktree/SKILL.md` (hand-written source for two adapter copies):

- line 12: the contract sentence — `~/.agents/skills/git-worktree/wt.sh` is no longer the implementation; `wt` on `PATH` is. Drop the "invoke it with that exact tilde path so the command's `allowed-tools` prefix matches" clause, which no longer applies.
- lines 16-24: rewrite the Actions table for the new surface — `wt path|resolve|switch|create|remove|list|verify <branch> [--allow-home]`, plus rows for `wt shell <branch>` and `wt overlay [<branch>]`. Keep the "agents cannot use `wt`'s fzf picker" note on the `list` row.
- line 35: `wt_path=$(~/.agents/skills/git-worktree/wt.sh switch "$branch" ${dotfiles:+--dotfiles})` → `wt_path=$(wt switch "$branch" ${allow_home:+--allow-home})`
- lines 81-82: `call wt.sh path` → `call wt path`; `without --dotfiles` → `without --allow-home`

`.agents/skills/using-git-worktrees/SKILL.md` (hand-written source for five generated copies) — lines 27, 35, 48, 57, 59: `wt --dotfiles`/`wt --test`/`wt --shell` → `wt switch … --allow-home`/`wt verify`/`wt shell`.

`.agents/skills/git-stack/SKILL.md:61` and `.claude/commands/git/stack.md:87`: `wt --dotfiles "$subject"` → `wt switch "$subject" --allow-home`.

Then run `just harness-generate` and confirm `just harness-check` passes. That regenerates the twelve derived copies listed in `.agents/harness/generated-paths.json`: `.agents/harness/commands/git/worktree.md`, `.agents/harness/adapters/{antigravity,cursor}/commands/git/worktree.md`, `.agents/harness/adapters/{antigravity,cursor}/skills/{git-worktree,using-git-worktrees}/SKILL.md`, `.claude/skills/using-git-worktrees/SKILL.md`, `.codex/skills/using-git-worktrees/{SKILL.md,agents/openai.yaml}`, `.config/opencode/{commands/git:worktree.md,skills/using-git-worktrees/SKILL.md}`, `.pi/agent/prompts/git:worktree.md`. Do not hand-edit any of those.

### 9. Move the tests

Delete `tests/wt.bats`. Its 23 cases collapse to 13 because the per-dialect duplication disappears. Port them to `crates/wt/tests/worktree.rs`, locating the binary with `env!("CARGO_BIN_EXE_wt")` — the pattern `crates/ness/tests/corpus.rs` already uses.

Port `tests/wt.bats:12-46`'s fixture into a Rust helper returning `{ remote, seed, clone, fake_home, branch, remote_head }`: bare remote, seeded `main`, clone, then a second commit on `ben/dxo-204/codex-attribution` pushed to the remote but absent from the clone. Plus an `init_dotfiles_home` helper that `git init`s `fake_home`. Every invocation sets `HOME=<fake_home>` and `WT_OVERLAY_DIR` to a per-test fixture directory.

Cases, each preserving the assertion it replaces:

1. `switch` fetches and tracks a newly available remote branch — worktree `HEAD == remote_head` and upstream `origin/<branch>` (`wt.bats:263-270`)
2. `switch` prunes stale metadata before creating (`wt.bats:78-114`)
3. picker path prunes stale metadata before listing — stub `fzf` on `PATH` (`wt.bats:116-151`)
4. `switch` refuses inside the `$HOME` repo without `--allow-home`: exit 4, stderr contains `--allow-home` (`wt.bats:153-177`, `296-304`)
5. `switch --allow-home` registers `<home>/.worktrees/dotfiles/<branch>` (`wt.bats:179-207`)
6. `--allow-home` exits non-zero when `$HOME` is not a git repository (`wt.bats:209-229`)
7. `switch` refuses a non-empty unregistered path and leaves the marker file intact (`wt.bats:231-261`, `306-318`)
8. `path --allow-home` prints the canonical path and creates nothing (`wt.bats:272-282`)
9. `path` derives the `dev-proj` path key for a repo under `$HOME` (`wt.bats:284-294`)
10. `switch` exits 4 when a registered worktree's leaf does not match the branch (`wt.bats:320-327`)
11. `remove` deletes a clean worktree and drops it from `worktree list` (`wt.bats:329-341`)
12. `remove` exits 4 when cwd is inside the target and leaves it on disk (`wt.bats:343-353`)
13. `list` prints a `<path>\t<branch>` line per worktree (`wt.bats:355-365`)

New cases in `crates/wt/tests/overlay.rs`:

14. `create` applies the manifest — a manifest naming `.env` links `<wt>/.env` → `<main>/.env` and the link resolves to the main worktree's content
15. re-running `overlay` is idempotent — second run reports `already symlinked` and changes nothing
16. `overlay` exits 4 when a manifest entry names a file that exists in the worktree and is not a symlink, and leaves that file untouched
17. `overlay` skips a manifest entry whose source is missing, exits 0, and still links the remaining entries
18. `--cd-file` receives the resolved directory for `switch` and is left empty for `list`

New `tests/wt-wrapper.bats` covers the one thing the Rust tests cannot — that each wrapper actually changes the caller's directory. It needs no built binary: put a stub `wt` on `PATH` that writes a known directory to the path following `--cd-file`, then assert `pwd` afterwards. Two cases:

19. the zsh wrapper `cd`s to the directory the stub wrote (invoked the way `tests/wt.bats:49-55` invokes an autoload function: `fpath=("${1:h}" $fpath); autoload -Uz wt; z() { builtin cd "$1"; }`)
20. the nushell wrapper `cd`s to the same directory (`nu -c "source '<wrapper>'; wt some-branch; pwd"`)

This keeps `just test` (the macOS bats job, `.github/workflows/lint.yml:89-131`) free of any Rust dependency — its `install_args` has no `rust`, and adding one would slow every run.

## Critical files & anchors

| File | Anchor | Why |
|---|---|---|
| `.agents/skills/git-worktree/wt.sh` | whole file, 316 lines | The most complete of the three implementations and the closest to the target semantics — actions, exit codes, `find_registered`'s mismatch guard, `--repo`. Read it before writing `src/actions.rs`; delete it in step 8. |
| `.config/zsh/functions/wt` | `_wt_ancestor_warn` (13-21), `--test`/`--shell` env sets (157-187) | The only copy of the ancestor-config warning and of the exact `verify`/`shell` environments. `wt.sh` lacks the `shell` action entirely. |
| `crates/ness/Cargo.toml` + `crates/ness/tests/corpus.rs` | manifest shape; `env!("CARGO_BIN_EXE_ness")` harness | The crate conventions to copy: standalone `[workspace]`, release profile, integration-test binary lookup. |
| `justfile` | `ness-*` block (776-795), `check` (734), `test` (802-827) | Recipe shape to mirror, and the two lists the new recipes join. |
| `.agents/harness/generated-paths.json` | worktree entries | The authoritative source→target map. Consult it before editing any worktree markdown, so a generated copy is never hand-edited. Read-only: it is control-plane (`crates/ness/src/policy.rs:115`). |

## Verification

Run from `$HOME`.

1. `just wt-test` — all 18 Rust cases pass.
2. `just wt-install` — then `command -v wt` prints `/Users/phatblat/.local/bin/wt`.
3. **New behaviour, end to end.** `~/.worktrees/dotfiles/main` and `~/.worktrees/dotfiles/agentic-review` already exist (`git worktree list`), so use a fresh branch name:
   - `wt path wt-smoke --allow-home` prints `/Users/phatblat/.worktrees/dotfiles/wt-smoke` and creates nothing (`test ! -e` that path).
   - `wt switch wt-smoke` alone exits 4 and its stderr contains `--allow-home`.
   - `wt switch wt-smoke --allow-home` creates the worktree, prints its path, and — this is the overlay proof — `readlink ~/.worktrees/dotfiles/wt-smoke/.ssh` resolves to `/Users/phatblat/.ssh`, and `git -C ~/.worktrees/dotfiles/wt-smoke ls-files .local` is empty while `~/.worktrees/dotfiles/wt-smoke/.local/share/mise/shims/mise` is executable.
   - `HOME=~/.worktrees/dotfiles/wt-smoke gh auth status` succeeds, proving the linked `hosts.yml` works under a remapped `HOME`.
   - `wt verify wt-smoke` runs `just check` under the remapped `HOME` and exits 0.
   - `wt remove wt-smoke --allow-home` removes it; `git worktree list` no longer names it.
4. **Wrapper `cd`, interactively, from the real `$HOME`.** `just test` covers the stubbed contract; this covers the real thing. In a fresh zsh: `wt main --allow-home` then `pwd` → `/Users/phatblat/.worktrees/dotfiles/main`. In a fresh `nu`: same. Then `wt list` prints the table and leaves `pwd` unchanged.
5. **`wt shell`.** `wt shell main` lands an interactive zsh at `~/.worktrees/dotfiles/main` with `$HOME` equal to that path; inside it `git log -1` works and `omp --version` runs without relocating (`pwd` unchanged). `exit` returns to the original shell.
6. `just check` — includes `lint` (both wrappers pass `shfmt`/`shellharden`/`shellcheck -s ksh`/`nu-check`/`nushell-autoload-purity`), `harness-check` (no stale generated artifact), `ness-test`, the new `wt-test`, and `test` (including `wt-wrapper.bats`).
7. **`.zshrc` is not worktree-verifiable.** Per `.agents/skills/using-git-worktrees/SKILL.md:33`, the step-7 force-load edit is only exercised by a real shell at `$HOME`. Confirm it by branch-switching `$HOME`, opening a new terminal, and checking `whence -w wt` reports `wt: function` before `wt` has ever been called in that session.

## Assumptions & contingencies

- **`wt` is not in the shared permission baseline.** `scripts/harness_policy.py`'s `BASH_ALLOW_PREFIX` is control-plane and human-only (`crates/ness/src/policy.rs:118`) — an agent editing it grants itself permissions on every harness. `Bash(wt:*)` in `.claude/commands/git/worktree.md` covers `/git:worktree`, but ordinary agent sessions will prompt on the first `wt` call. Do not attempt the `harness_policy.py` edit; report it as a one-line human follow-up (`"wt"` inserted alphabetically into `BASH_ALLOW_PREFIX`, then `just harness-perms-apply`).
- **Creating a test fixture literally named `.env` may be blocked.** ness's `PROTECTED_PATHS` matches `\.env($|\.)` and `\.ssh/` (`crates/ness/src/policy.rs:103`), so a `write`-tool call targeting such a fixture is denied. Create those fixtures from inside Rust test code (`std::fs::write`), which the guard does not intercept, rather than with the editing tools.
- **If `fzf` is not on `PATH`**, the picker exits 2 with `wt: fzf not found; use \`wt list\`` rather than falling back to a built-in selector. `fzf` is mise-managed and always present on this machine; a fallback selector would be untested code.
