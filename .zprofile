#-------------------------------------------------------------------------------
#
# .zprofile
#
# .zprofile is for login shells. It is basically the same as .zlogin except that it's sourced before .zshrc whereas .zlogin is sourced after .zshrc. According to the zsh documentation, ".zprofile is meant as an alternative to .zlogin for ksh fans; the two are not intended to be used together, although this could certainly be done if desired."
#
# https://unix.stackexchange.com/questions/71253/what-should-shouldnt-go-in-zshenv-zshrc-zlogin-zprofile-zlogout/71258#71258
#
#-------------------------------------------------------------------------------

# echo ".zprofile"

# Homebrew
export PATH="/opt/homebrew/bin:$PATH"
eval "$(brew shellenv)"

# FVM
export PATH="$HOME/fvm/default/bin:$PATH"

# Cargo
source $HOME/.cargo/env

# Jebrains Toolbox App scripts
export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source $HOME/.orbstack/shell/init.zsh 2>/dev/null || :

# Java (mise-managed)
export JAVA_HOME="$($HOME/.local/bin/mise where java)"
export PATH="$JAVA_HOME/bin:$PATH"

# Expose CLI paths to GUI apps (e.g. CodexBar)
launchctl setenv CLAUDE_CLI_PATH "$HOME/.local/bin/claude"

# Aliases
alias ll='ls -l'
alias la='ls -la'



# zsh already auto-sources .zshrc for interactive shells, so sourcing it here
# as well would apply every PATH export (and every other side effect) twice.
# Only source it for non-interactive login shells, which still need the
# autoloaded functions.
if [[ ! -o interactive && -r "$HOME/.zshrc" ]]; then
  source "$HOME/.zshrc"
fi

# Added by Obsidian
export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"
