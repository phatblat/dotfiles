#!/usr/bin/env bats
# Regression tests for justfile recipes that orchestrate external tools.

@test "root justfile: settings and default recipe follow shared conventions" {
  run just --justfile "$BATS_TEST_DIRNAME/../justfile" --dump --dump-format json
  [ "$status" -eq 0 ]
  dump="$output"

  [ "$(jq -r '.settings.export' <<<"$dump")" = false ]
  [ "$(jq -r '.settings.quiet' <<<"$dump")" = false ]
  [ "$(jq -r '.assignments.PATH.export' <<<"$dump")" = true ]
  [ "$(jq -r '.first' <<<"$dump")" = "_default" ]
  [ "$(jq -r '(.recipes._default.attributes | index("default")) != null' <<<"$dump")" = true ]
  [ "$(jq -r '(.recipes._default.attributes | all(. != {"script": null}))' <<<"$dump")" = true ]
  [ "$(jq -c '.recipes._default.body' <<<"$dump")" = '[["@just --list"]]' ]

  run just --justfile "$BATS_TEST_DIRNAME/../justfile"
  [ "$status" -eq 0 ]
  [[ "$output" == "Available recipes:"* ]]
  [[ "$output" != *"just --list"* ]]
  [[ "$output" != *"_default"* ]]
}

@test "upgrade-mise-tools-commit ignores tools without a version bump" {
  local bindir="$BATS_TEST_TMPDIR/bin"
  local home="$BATS_TEST_TMPDIR/home"
  local log="$BATS_TEST_TMPDIR/commands.log"

  mkdir -p "$bindir" "$home/.config/mise"

  cat >"$bindir/mise" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "config" && "$2" == "get" && "$3" == "tools" ]]; then
  printf '[%s]\n' "cargo:https://example.test/wookie"
  exit 0
fi
if [[ "$1" == "outdated" && "$2" == "--bump" && "$3" == "--json" ]]; then
  printf '%s\n' '{"cargo:https://example.test/wookie":{"current":"rev:abc","bump":null}}'
  exit 0
fi
printf 'mise %s\n' "$*" >>"$COMMAND_LOG"
EOF
  chmod +x "$bindir/mise"

  cat >"$bindir/git" <<'EOF'
#!/usr/bin/env bash
printf 'git %s\n' "$*" >>"$COMMAND_LOG"
exit 1
EOF
  chmod +x "$bindir/git"

  run env HOME="$home" PATH="$bindir:$PATH" COMMAND_LOG="$log" \
    just --justfile "$BATS_TEST_DIRNAME/../justfile" upgrade-mise-tools-commit

  [ "$status" -eq 0 ]
  [[ "$output" == *"All tools are up to date"* ]]
  [ ! -e "$log" ]
}

@test "list-claude-models prints lockfile model IDs" {
  local home="$BATS_TEST_TMPDIR/home"
  mkdir -p "$home/.claude"
  cat >"$home/.claude/models.lock" <<'EOF'
# Claude model catalog
  claude-opus-5                 - Active
  claude-sonnet-5               - Active
EOF

  # The recipe resolves paths via `justfile_directory()`, not `$HOME`, so the
  # justfile itself has to live alongside the fixture lockfile.
  cp "$BATS_TEST_DIRNAME/../justfile" "$home/justfile"

  run just --justfile "$home/justfile" list-claude-models

  [ "$status" -eq 0 ]
  [ "$output" = $'claude-opus-5\nclaude-sonnet-5' ]
}

@test "upgrade-mise-tools-commit commits the version bump without hardcoded attribution" {
  local bindir="$BATS_TEST_TMPDIR/bin"
  local home="$BATS_TEST_TMPDIR/home"
  local log="$BATS_TEST_TMPDIR/commands.log"

  mkdir -p "$bindir" "$home/.config/mise"
  touch "$home/.config/mise/config.toml"

  cat >"$bindir/mise" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "config" && "$2" == "get" && "$3" == "tools" ]]; then
  printf '[%s]\n' "npm:example"
  exit 0
fi
if [[ "$1" == "outdated" && "$2" == "--bump" && "$3" == "--json" ]]; then
  printf '%s\n' '{"npm:example":{"current":"1.0.0","bump":"1.1.0"}}'
  exit 0
fi
printf 'mise %s\n' "$*" >>"$COMMAND_LOG"
EOF
  chmod +x "$bindir/mise"

  cat >"$bindir/git" <<'EOF'
#!/usr/bin/env bash
printf 'git %s\n' "$*" >>"$COMMAND_LOG"
EOF
  chmod +x "$bindir/git"

  # The recipe resolves paths via `justfile_directory()`, not `$HOME`, so the
  # justfile itself has to live alongside the fixture mise config, and
  # format-mise's sort-tools.py has to live alongside the justfile.
  cp "$BATS_TEST_DIRNAME/../justfile" "$home/justfile"
  mkdir -p "$home/scripts"
  cp "$BATS_TEST_DIRNAME/../scripts/sort-tools.py" "$home/scripts/sort-tools.py"

  run env HOME="$home" PATH="$bindir:$PATH" COMMAND_LOG="$log" \
    just --justfile "$home/justfile" upgrade-mise-tools-commit

  [ "$status" -eq 0 ]
  grep -Fq "git commit --only $home/.config/mise/config.toml -m chore: bump npm:example 1.0.0 → 1.1.0" "$log"
  ! grep -Fq "Co-Authored-By" "$log"
}


# Writes a fake `gh` into $1 whose `extension list` prints the tab-separated
# rows given on stdin, and which logs every other invocation to $COMMAND_LOG.
fake_gh() {
  local bindir="$1"
  mkdir -p "$bindir"
  cat >"$bindir/gh" <<EOF
#!/usr/bin/env bash
if [[ "\$1 \$2" == "extension list" ]]; then
  printf '%s' '$(cat)'
  exit 0
fi
printf 'gh %s\n' "\$*" >>"\$COMMAND_LOG"
EOF
  chmod +x "$bindir/gh"
}

@test "install-gh-extensions skips extensions already installed" {
  local bindir="$BATS_TEST_TMPDIR/bin"
  local log="$BATS_TEST_TMPDIR/commands.log"
  local manifest="$BATS_TEST_TMPDIR/extensions.txt"

  printf 'gh aw\tgithub/gh-aw\tv0.85.4\n' | fake_gh "$bindir"
  printf 'github/gh-aw\n' >"$manifest"

  run env PATH="$bindir:$PATH" COMMAND_LOG="$log" \
    just --justfile "$BATS_TEST_DIRNAME/../justfile" \
    --set gh_extensions_manifest "$manifest" install-gh-extensions

  [ "$status" -eq 0 ]
  [[ "$output" == *"github/gh-aw already installed"* ]]
  # No install was attempted, so the mock never logged anything.
  [ ! -e "$log" ]
}

@test "install-gh-extensions installs extensions missing from the list" {
  local bindir="$BATS_TEST_TMPDIR/bin"
  local log="$BATS_TEST_TMPDIR/commands.log"
  local manifest="$BATS_TEST_TMPDIR/extensions.txt"

  printf 'gh aw\tgithub/gh-aw\tv0.85.4\n' | fake_gh "$bindir"
  printf 'github/gh-aw\nmislav/gh-branch\n' >"$manifest"

  run env PATH="$bindir:$PATH" COMMAND_LOG="$log" \
    just --justfile "$BATS_TEST_DIRNAME/../justfile" \
    --set gh_extensions_manifest "$manifest" install-gh-extensions

  [ "$status" -eq 0 ]
  grep -Fqx "gh extension install mislav/gh-branch" "$log"
  # The already-installed one must not be reinstalled.
  ! grep -Fq "github/gh-aw" "$log"
}

@test "install-gh-extensions ignores comments and blank lines" {
  local bindir="$BATS_TEST_TMPDIR/bin"
  local log="$BATS_TEST_TMPDIR/commands.log"
  local manifest="$BATS_TEST_TMPDIR/extensions.txt"

  printf '' | fake_gh "$bindir"
  printf '# a comment\n\ngithub/gh-aw\n' >"$manifest"

  run env PATH="$bindir:$PATH" COMMAND_LOG="$log" \
    just --justfile "$BATS_TEST_DIRNAME/../justfile" \
    --set gh_extensions_manifest "$manifest" install-gh-extensions

  [ "$status" -eq 0 ]
  [ "$(wc -l <"$log")" -eq 1 ]
  grep -Fqx "gh extension install github/gh-aw" "$log"
}

@test "install-gh-extensions does not treat a repo prefix as installed" {
  local bindir="$BATS_TEST_TMPDIR/bin"
  local log="$BATS_TEST_TMPDIR/commands.log"
  local manifest="$BATS_TEST_TMPDIR/extensions.txt"

  # `github/gh-aw` is a substring of the installed `github/gh-aw-extras`,
  # so a non-anchored match would wrongly report it as already installed.
  printf 'gh aw-extras\tgithub/gh-aw-extras\tv1.0.0\n' | fake_gh "$bindir"
  printf 'github/gh-aw\n' >"$manifest"

  run env PATH="$bindir:$PATH" COMMAND_LOG="$log" \
    just --justfile "$BATS_TEST_DIRNAME/../justfile" \
    --set gh_extensions_manifest "$manifest" install-gh-extensions

  [ "$status" -eq 0 ]
  grep -Fqx "gh extension install github/gh-aw" "$log"
}

@test "install-gh-extensions is a no-op when the manifest is missing" {
  local bindir="$BATS_TEST_TMPDIR/bin"
  local log="$BATS_TEST_TMPDIR/commands.log"

  printf '' | fake_gh "$bindir"

  run env PATH="$bindir:$PATH" COMMAND_LOG="$log" \
    just --justfile "$BATS_TEST_DIRNAME/../justfile" \
    --set gh_extensions_manifest "$BATS_TEST_TMPDIR/absent.txt" install-gh-extensions

  [ "$status" -eq 0 ]
  [ ! -e "$log" ]
}

@test "upgrade-mise-tools-commit leaves unrelated staged work uncommitted" {
  local bindir="$BATS_TEST_TMPDIR/bin"
  local repo="$BATS_TEST_TMPDIR/repo"

  mkdir -p "$bindir" "$repo/.config/mise" "$BATS_TEST_TMPDIR/nohooks"

  # A real git in a throwaway repo: only `mise` is faked, so this exercises
  # actual commit semantics rather than a logged command string.
  git -C "$repo" init -q
  git -C "$repo" config user.email test@example.test
  git -C "$repo" config user.name Test
  git -C "$repo" config commit.gpgsign false
  git -C "$repo" config core.hooksPath "$BATS_TEST_TMPDIR/nohooks"
  printf 'version = "1.0.0"\n' >"$repo/.config/mise/config.toml"
  printf 'original\n' >"$repo/unrelated.txt"
  git -C "$repo" add .
  git -C "$repo" commit -qm seed

  cat >"$bindir/mise" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "config" && "$2" == "get" && "$3" == "tools" ]]; then
  printf '[%s]\n' "npm:example"
  exit 0
fi
if [[ "$1" == "outdated" && "$2" == "--bump" && "$3" == "--json" ]]; then
  printf '%s\n' '{"npm:example":{"current":"1.0.0","bump":"1.1.0"}}'
  exit 0
fi
printf 'version = "1.1.0"\n' >"$HOME/.config/mise/config.toml"
EOF
  chmod +x "$bindir/mise"

  # Unrelated work staged before the recipe runs -- the race that once swept
  # feature files into a version-bump commit.
  printf 'staged edit\n' >"$repo/unrelated.txt"
  git -C "$repo" add unrelated.txt

  # The recipe resolves paths via `justfile_directory()`, which also becomes
  # the recipe's cwd, so the justfile has to live inside the throwaway repo
  # or the recipe would commit against the real justfile's own directory.
  # format-mise's sort-tools.py has to live alongside it too.
  cp "$BATS_TEST_DIRNAME/../justfile" "$repo/justfile"
  mkdir -p "$repo/scripts"
  cp "$BATS_TEST_DIRNAME/../scripts/sort-tools.py" "$repo/scripts/sort-tools.py"

  run env HOME="$repo" PATH="$bindir:$PATH" \
    just --justfile "$repo/justfile" upgrade-mise-tools-commit

  [ "$status" -eq 0 ]
  # The bump commit carries the mise config and nothing else.
  [ "$(git -C "$repo" show --pretty='' --name-only HEAD)" = ".config/mise/config.toml" ]
  # The unrelated edit is still staged, and its committed content is untouched.
  git -C "$repo" diff --cached --name-only | grep -Fqx unrelated.txt
  [ "$(git -C "$repo" show HEAD:unrelated.txt)" = original ]
}

@test "root justfile: build and clean wire up the lifecycle recipes" {
  run just --justfile "$BATS_TEST_DIRNAME/../justfile" --dump --dump-format json
  [ "$status" -eq 0 ]
  dump="$output"

  [ "$(jq -r '[.recipes.build.dependencies[].recipe] | join(" ")' <<<"$dump")" = "generate" ]
  [ "$(jq -r '(.recipes.build.attributes | index({"group":"build"})) != null' <<<"$dump")" = true ]
  [ "$(jq -r '(.recipes.generate.attributes | index({"group":"build"})) != null' <<<"$dump")" = true ]
  [ "$(jq -r '(.recipes["harness-generate"].attributes | index({"group":"build"})) != null' <<<"$dump")" = true ]
  [ "$(jq -r '[.recipes.clean.dependencies[].recipe] | join(" ")' <<<"$dump")" \
    = "clean-rust clean-caches clean-build clean-deps" ]
  [ "$(jq -r '[.recipes.deps.dependencies[].recipe] | index("install-bun-deps") != null' <<<"$dump")" = true ]
}

@test "clean-build removes untracked build output and keeps tracked directories" {
  local repo="$BATS_TEST_TMPDIR/repo"

  mkdir -p "$repo/scripts/__pycache__" "$repo/docs/dist" \
    "$repo/.claude/skills/gstack/browse/dist" "$repo/.ruff_cache" \
    "$repo/.omp/plugins/node_modules/pkg/dist" "$BATS_TEST_TMPDIR/nohooks"
  touch "$repo/scripts/__pycache__/stale.pyc" "$repo/docs/dist/keep.txt" \
    "$repo/.claude/skills/gstack/browse/dist/browse" "$repo/.ruff_cache/cache" \
    "$repo/.omp/plugins/node_modules/pkg/dist/index.js"

  git -C "$repo" init -q
  git -C "$repo" config user.email test@example.test
  git -C "$repo" config user.name Test
  git -C "$repo" config commit.gpgsign false
  git -C "$repo" config core.hooksPath "$BATS_TEST_TMPDIR/nohooks"
  git -C "$repo" add docs/dist/keep.txt
  git -C "$repo" commit -qm seed

  # The recipe cds to justfile_directory(), so the justfile must live in the repo.
  cp "$BATS_TEST_DIRNAME/../justfile" "$repo/justfile"

  run just --justfile "$repo/justfile" clean-build
  [ "$status" -eq 0 ]

  # Untracked output under a scanned root, and at the repo root, is gone.
  [ ! -d "$repo/scripts/__pycache__" ]
  [ ! -d "$repo/.ruff_cache" ]
  # A tracked directory survives even though its name is on the artifact list.
  [ -f "$repo/docs/dist/keep.txt" ]
  # The vendored gstack tree is not a scanned root.
  [ -f "$repo/.claude/skills/gstack/browse/dist/browse" ]
  # node_modules interiors are pruned from the scan.
  [ -f "$repo/.omp/plugins/node_modules/pkg/dist/index.js" ]
}