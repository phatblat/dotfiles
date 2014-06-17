#-------------------------------------------------------------------------------
#
# Terminal colors
# http://stackoverflow.com/questions/1355976/bash-on-snow-leopard-doesnt-obey-terminal-colours
#
#-------------------------------------------------------------------------------

# Colors
export TERM=xterm-256color
export GREP_OPTIONS='--color=auto' GREP_COLOR='1;32'
export CLICOLOR=1
export LSCOLORS=ExGxFxDxCxHxHxCbCeEbEb

# Setup some colors to use later in interactive shell or scripts
export COLOR_NC='\033[0m' # No Color
export COLOR_WHITE='\033[1;37m'
export COLOR_BLACK='\033[0;30m'
export COLOR_BLUE='\033[0;34m'
export COLOR_LIGHT_BLUE='\033[1;34m'
export COLOR_GREEN='\033[0;32m'
export COLOR_LIGHT_GREEN='\033[1;32m'
export COLOR_CYAN='\033[0;36m'
export COLOR_LIGHT_CYAN='\033[1;36m'
export COLOR_RED='\033[0;31m'
export COLOR_LIGHT_RED='\033[1;31m'
export COLOR_PURPLE='\033[0;35m'
export COLOR_LIGHT_PURPLE='\033[1;35m'
export COLOR_BROWN='\033[0;33m'
export COLOR_YELLOW='\033[1;33m'
export COLOR_GRAY='\033[1;30m'
export COLOR_LIGHT_GRAY='\033[0;37m'


#-------------------------------------------------------------------------------
#
# Prompt customization
#
#-------------------------------------------------------------------------------
# Save and reload the history after each command finishes
#export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

# Check for functions from git-sh
if [ $(type -t _git_headname > /dev/null) ]; then
    # Use prompt from git-sh
    PS1='`_git_headname``_git_upstream_state`!`_git_repo_state``_git_workdir``_git_dirty``_git_dirty_stash`> '
else
    # git-sh not loaded, use personal prompt customization
    function git_branch {
        ref=$(git symbolic-ref HEAD 2> /dev/null) || return
        echo -n ${ref#refs/heads/}
    }

    function parse_git_branch {
        ref=$(git symbolic-ref HEAD 2> /dev/null) || return
        echo " ("$(git_branch)")"
    }

    PS1="\[$COLOR_LIGHT_GRAY\]\$(date +%H:%M) \[$COLOR_RED\]\w\[$COLOR_YELLOW\]\$(parse_git_branch)\[$COLOR_GREEN\] \[$COLOR_CYAN\]$ \[$COLOR_NC\]"
fi

