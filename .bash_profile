#!/usr/bin/env bash
#
# .bash_profile
#

export MISE_PIN=1

# Source Nix profile
if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
  . ~/.nix-profile/etc/profile.d/nix.sh
fi

# Add Nix profile bin to PATH if not already present
if [ -d ~/.nix-profile/bin ]; then
  export PATH="$HOME/.nix-profile/bin:$PATH"
fi

# linux PATHs
# export PATH=/snap/bin:${PATH}
# export PATH=/home/linuxbrew/.linuxbrew/sbin:${PATH}
# export PATH=/home/linuxbrew/.linuxbrew/bin:${PATH}

export PATH="/opt/homebrew/bin:$PATH"

. "$HOME/.cargo/env"

source "$HOME/.config/broot/launcher/bash/br"

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

export HOMEBREW_PREFIX=$(brew --prefix)

# JDK
export JAVA_HOME=/opt/homebrew/opt/openjdk@17

# Aliases
alias ll='ls -l'
alias la='ls -la'

# NVM
export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[ -f "$HOME/.config/.dart-cli-completion/bash-config.bash" ] && . "$HOME/.config/.dart-cli-completion/bash-config.bash" || true
## [/Completion]

. "$HOME/.cargo/env"

# Added by Windsurf
export PATH="$HOME/.codeium/windsurf/bin:$PATH"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source "$HOME/.orbstack/shell/init.bash" 2>/dev/null || :

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/phatblat/.cache/lm-studio/bin"
# End of LM Studio CLI section
