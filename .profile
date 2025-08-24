#!/usr/bin/bash

# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        # shellcheck source=/dev/null
        . "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# shellcheck source=/dev/null
. "$HOME/.cargo/env"


# Added by JetBrains Toolbox
export PATH="$PATH:/Users/zoltar/Library/Application Support/JetBrains/Toolbox/scripts"
# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

export NVM_DIR="$HOME/.nvm"
        # shellcheck source=/dev/null
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

export NVM_DIR="$HOME/.config/nvm"
        # shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/phatblat/.cache/lm-studio/bin"
# End of LM Studio CLI section

# Claude function - Run local claude installation or install if missing
claude() {
    if [ -e .claude/local/claude ]; then
        ~/.claude/local/claude "$@"
    else
        echo "Claude not found locally. Installing..."
        mise exec npm:@anthropic-ai/claude-code -- claude migrate-installer

        # After installation, run the command if it now exists
        if [ -e .claude/local/claude ]; then
            ~/.claude/local/claude "$@"
        else
            echo "Installation may have failed. Please check the output above."
            return 1
        fi
    fi
}

