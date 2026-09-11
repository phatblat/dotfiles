# brew — Homebrew package management

# Installs Homebrew packages from Brewfile
[group('brew')]
install-brew:
    brew bundle install

# Regenerates ~/Brewfile from current installs, minus mise-managed duplicates
[group('brew')]
dump-brew:
    python3 {{ justfile_directory() }}/scripts/brew-dump.py

# Updates homebrew and lists outdated formulae/casks
[group('brew')]
update-brew:
    brew update && brew outdated

# Upgrades homebrew formulae/casks (pass args through to brew upgrade)
[group('brew')]
upgrade-brew *args:
    NONINTERACTIVE=1 brew upgrade {{ args }}

# Flags CLI tools installed via both mise and Homebrew
[group('brew')]
package-audit:
    python3 {{ justfile_directory() }}/scripts/audit-package-managers.py
