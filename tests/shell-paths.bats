#!/usr/bin/env bats

load helpers/setup

@test "local bin follows Homebrew and mise in interactive shell configs" {
  run python3 - "$HOME" <<'PY'
from pathlib import Path
import sys

home = Path(sys.argv[1])
checks = {
    '.zshrc': ('eval "$(mise activate zsh)"', 'export PATH="$PATH:$HOME/.local/bin"'),
    '.bashrc': ('eval "$(mise activate bash)"', 'export PATH="$PATH:$HOME/.local/bin"'),
    '.config/fish/config.fish': ('mise activate fish | source', 'fish_add_path --append --path ~/.local/bin'),
    '.config/nushell/config.nu': ('source $mise_init', '$env.PATH ++= [($nu.home-dir | path join \'.local\' \'bin\')]'),
}

for relative, (before, after) in checks.items():
    content = (home / relative).read_text()
    assert before in content, f'{relative}: missing {before}'
    assert after in content, f'{relative}: missing {after}'
    assert content.index(before) < content.index(after), f'{relative}: local bin precedes mise'
PY

  [ "$status" -eq 0 ]
}
