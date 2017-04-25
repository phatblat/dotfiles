#-------------------------------------------------------------------------------
#
# options.zsh
# Shell options - http://zsh.sourceforge.net/Doc/Release/Options.html
#
#-------------------------------------------------------------------------------

export TERM="xterm-256color"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"

# NOMATCH (+3) <C> <Z>
# If a pattern for filename generation has no matches, print an error, instead
# of leaving it unchanged in the argument list. This also applies to file
# expansion of an initial ‘~’ or ‘=’. (Allow [ or ] whereever you want)
unsetopt nomatch

# Current zsh options
setopt alwaystoend
setopt autocd
setopt autopushd
setopt completeinword
setopt noflowcontrol
setopt interactive
setopt interactivecomments
setopt login
setopt longlistjobs
setopt monitor
setopt nonomatch
setopt promptsubst
setopt pushdignoredups
setopt pushdminus
setopt zle


# History
# https://www.digitalocean.com/community/tutorials/how-to-use-bash-history-commands-and-expansions-on-a-linux-vps

# INC_APPEND_HISTORY
# This options works like APPEND_HISTORY except that new history lines are added to the $HISTFILE incrementally (as soon as they are entered), rather than waiting until the shell exits. The file will still be periodically re-written to trim it when the number of lines grows 20% beyond the value specified by $SAVEHIST (see also the HIST_SAVE_BY_COPY option).
unsetopt inc_append_history

# INC_APPEND_HISTORY_TIME
# This option is a variant of INC_APPEND_HISTORY in which, where possible, the history entry is written out to the file after the command is finished, so that the time taken by the command is recorded correctly in the history file in EXTENDED_HISTORY format. This means that the history entry will not be available immediately from other instances of the shell that are using the same history file.
#
# This option is only useful if INC_APPEND_HISTORY and SHARE_HISTORY are turned off. The three options should be considered mutually exclusive.
unsetopt inc_append_history_time

# SHARE_HISTORY <K>
# This option both imports new commands from the history file, and also causes your typed commands to be appended to the history file (the latter is like specifying INC_APPEND_HISTORY, which should be turned off if this option is in effect). The history lines are also output with timestamps ala EXTENDED_HISTORY (which makes it easier to find the spot where we left off reading the file after it gets re-written)
setopt share_history

# EXTENDED_HISTORY <C>
# Save each command’s beginning timestamp (in seconds since the epoch) and the duration (in seconds) to the history file. The format of this prefixed data is:
#
# ‘: <beginning time>:<elapsed seconds>;<command>’.
setopt extended_history

setopt histexpiredupsfirst
# setopt histignoredups
setopt histignorespace

# HIST_VERIFY
# Whenever the user enters a line with history expansion, don’t execute the
# line directly; instead, perform history expansion and reload the line into the editing buffer.
setopt hist_verify

# HIST_IGNORE_ALL_DUPS
# If a new command line being added to the history list duplicates an older
# one, the older command is removed from the list (even if it is not the previous event).
setopt hist_ignore_all_dups

# HISTSIZE=5000
# # HISTFILESIZE=10000
# SAVEHIST=10000
# HIST_IGNORE_ALL_DUPS