#!/usr/bin/env bats
# wt-wrapper.bats — proves each shell wrapper `cd`s the caller's shell to the
# directory the `wt` binary writes to --cd-file. Needs no built binary: a
# stub `wt` on PATH writes a known directory to the path following
# --cd-file, and each case asserts pwd.

bats_require_minimum_version 1.5.0

load helpers/setup

ZSH_WT="$HOME/.config/zsh/functions/wt"
NU_WT="$HOME/.config/nushell/autoload/wt.nu"

setup() {
  dest="$BATS_TEST_TMPDIR/dest"
  mkdir -p "$dest"
  stub_bin="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$stub_bin"
}

# Writes a stub `wt` that finds the path after --cd-file and writes $dest to
# it, mirroring the real binary's --cd-file contract.
write_stub() {
  local exit_code="${1:-0}"
  cat > "$stub_bin/wt" << EOF
#!/bin/sh
cd_file=""
while [ \$# -gt 0 ]; do
  case "\$1" in
  --cd-file)
    cd_file=\$2
    shift 2
    ;;
  *)
    shift
    ;;
  esac
done
[ -n "\$cd_file" ] && printf '%s' "$dest" > "\$cd_file"
exit $exit_code
EOF
  chmod +x "$stub_bin/wt"
}

@test "zsh wrapper cds to the directory the stub wrote" {
  write_stub 0

  run env PATH="$stub_bin:$PATH" zsh -c '
    fpath=("${1:h}" $fpath)
    autoload -Uz wt
    z() { builtin cd "$1"; }
    wt some-branch
    pwd
  ' zsh "$ZSH_WT"

  [ "$status" -eq 0 ]
  [ "$output" = "$dest" ]
}

@test "nushell wrapper cds to the directory the stub wrote" {
  write_stub 0

  run env PATH="$stub_bin:$PATH" nu -c "source '$NU_WT'; wt some-branch; pwd | str trim"

  [ "$status" -eq 0 ]
  [ "$output" = "$dest" ]
}

@test "zsh wrapper surfaces the stub's exit code and leaves pwd unchanged when no cd-file is written" {
  cat > "$stub_bin/wt" << 'EOF'
#!/bin/sh
exit 7
EOF
  chmod +x "$stub_bin/wt"

  run env PATH="$stub_bin:$PATH" zsh -c '
    fpath=("${1:h}" $fpath)
    autoload -Uz wt
    z() { builtin cd "$1"; }
    start="$PWD"
    wt bogus-action-xyz
    rc=$?
    [[ "$PWD" == "$start" ]] || exit 99
    exit "$rc"
  ' zsh "$ZSH_WT"

  [ "$status" -eq 7 ]
}
