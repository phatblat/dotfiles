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

# NVM - Node version manager
# WARNING: NVM should be prefixed to the path _after_ Homebrew is added.
# The nvm.sh script won't fix ordering if it finds nvm in the path anywhere.
# export NVM_DIR="$HOME/.nvm"
# [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"  # This loads nvm
# [ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# JDK
export JAVA_HOME=/Library/Java/JavaVirtualMachines/android-studio

# Aliases
alias ll='ls -l'
alias la='ls -la'

# NVM
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

