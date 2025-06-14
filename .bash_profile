#!/usr/bin/env bash
#
# .bash_profile
#

# linux PATHs
# export PATH=/snap/bin:${PATH}
# export PATH=/home/linuxbrew/.linuxbrew/sbin:${PATH}
# export PATH=/home/linuxbrew/.linuxbrew/bin:${PATH}

export PATH="/opt/homebrew/bin:$PATH"

. "${HOME}/.cargo/env"

source /Users/phatblat/.config/broot/launcher/bash/br

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

export HOMEBREW_PREFIX=$(brew --prefix)

# JDK
export JAVA_HOME=/Library/Java/JavaVirtualMachines/android-studio

# Aliases
alias ll='ls -l'
alias la='ls -la'

# NVM
export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[ -f /Users/phatblat/.config/.dart-cli-completion/bash-config.bash ] && . /Users/phatblat/.config/.dart-cli-completion/bash-config.bash || true
## [/Completion]

. "$HOME/.cargo/env"

# Added by Windsurf
export PATH="/Users/phatblat/.codeium/windsurf/bin:$PATH"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.bash 2>/dev/null || :

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/phatblat/.cache/lm-studio/bin"
# End of LM Studio CLI section

