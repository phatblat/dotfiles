#-------------------------------------------------------------------------------
#
# shell/options.zsh
# Shell options - http://zsh.sourceforge.net/Doc/Release/Options.html
#
#-------------------------------------------------------------------------------

lj info 'shell/options.zsh'

export TERM="xterm-256color"
export LANGUAGE="en_US.UTF-8"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

#-------------------------------------------------------------------------------
# Changing Directories

# AUTO_CD (-J)
# If a command is issued that can’t be executed as a normal command, and the command is the name of a directory, perform the cd command to that directory. This option is only applicable if the option SHIN_STDIN is set, i.e. if commands are being read from standard input. The option is designed for interactive use; it is recommended that cd be used explicitly in scripts to avoid ambiguity
setopt auto_cd

# AUTO_PUSHD (-N)
# Make cd push the old directory onto the directory stack.
setopt auto_pushd

# PUSHD_IGNORE_DUPS
# Don’t push multiple copies of the same directory onto the directory stack.
setopt pushd_ignore_dups

# PUSHD_MINUS
# Exchanges the meanings of ‘+’ and ‘-’ when used with a number to specify a directory in the stack.
setopt pushd_minus

#-------------------------------------------------------------------------------
# Completion

# ALWAYS_TO_END
# If a completion is performed with the cursor within a word, and a full completion is inserted, the cursor is moved to the end of the word. That is, the cursor is moved to the end of the word if either a single match is inserted or menu completion is performed.
setopt always_to_end

# COMPLETE_IN_WORD
# If unset, the cursor is set to the end of the word if completion is started.
# Otherwise it stays there and completion is done from both ends.
setopt complete_in_word

#-------------------------------------------------------------------------------
# Expansion and Globbing

# EXTENDED_GLOB
# Treat the ‘#’, ‘~’ and ‘^’ characters as part of patterns for filename generation, etc. (An initial unquoted ‘~’ always produces named directory expansion.)
#
# Extended pattern matching
# https://www.gnu.org/software/bash/manual/html_node/Pattern-Matching.html#Pattern-Matching
#   ?() - zero or one occurrences of pattern
#   *() - zero or more occurrences of pattern
#   +() - one or more occurrences of pattern
#   @() - one occurrence of pattern
#   !() - anything except the pattern
#
# Example:
#   case $1 in
#       a*             ) foo;;    # matches anything starting with "a"
#       b?             ) bar;;    # matches any two-character string starting with "b"
#       c[de]          ) baz;;    # matches "cd" or "ce"
#       me?(e)t        ) qux;;    # matches "met" or "meet"
#       @(a|e|i|o|u)   ) fuzz;;   # matches one vowel
#       m+(iss)?(ippi) ) fizz;;   # matches "miss" or "mississippi" or others
#   esac
setopt extended_glob

# NOMATCH (+3) <C> <Z>
# If a pattern for filename generation has no matches, print an error, instead
# of leaving it unchanged in the argument list. This also applies to file
# expansion of an initial ‘~’ or ‘=’.
#
# Allow [ or ] whereever you want
# https://robots.thoughtbot.com/how-to-use-arguments-in-a-rake-task
unsetopt no_match

#-------------------------------------------------------------------------------
# History
# https://www.digitalocean.com/community/tutorials/how-to-use-bash-history-commands-and-expansions-on-a-linux-vps

# EXTENDED_HISTORY <C>
# Save each command’s beginning timestamp (in seconds since the epoch) and the duration (in seconds) to the history file. The format of this prefixed data is:
#
# ‘: <beginning time>:<elapsed seconds>;<command>’.
setopt extended_history

# HIST_EXPIRE_DUPS_FIRST
# If the internal history needs to be trimmed to add the current command line, setting this option will cause the oldest history event that has a duplicate to be lost before losing a unique event from the list. You should be sure to set the value of HISTSIZE to a larger number than SAVEHIST in order to give you some room for the duplicated events, otherwise this option will behave just like HIST_IGNORE_ALL_DUPS once the history fills up with unique events.
unsetopt hist_expire_dups_first

# HIST_IGNORE_ALL_DUPS
# If a new command line being added to the history list duplicates an older
# one, the older command is removed from the list (even if it is not the previous event).
setopt hist_ignore_all_dups

# HIST_IGNORE_DUPS (-h)
# Do not enter command lines into the history list if they are duplicates of the previous event.
setopt hist_ignore_dups

# HIST_IGNORE_SPACE (-g)
# Remove command lines from the history list when the first character on the line is a space, or when one of the expanded aliases contains a leading space. Only normal aliases (not global or suffix aliases) have this behaviour. Note that the command lingers in the internal history until the next command is entered before it vanishes, allowing you to briefly reuse or edit the line. If you want to make it vanish right away without entering another command, type a space and press return.
setopt hist_ignore_space

# HIST_NO_STORE
# Remove the history (fc -l) command from the history list when invoked. Note that the command lingers in the internal history until the next command is entered before it vanishes, allowing you to briefly reuse or edit the line.
setopt hist_no_store

# HIST_REDUCE_BLANKS
# Remove superfluous blanks from each command line being added to the history list.
setopt hist_reduce_blanks

# HIST_VERIFY
# Whenever the user enters a line with history expansion, don’t execute the
# line directly; instead, perform history expansion and reload the line into the editing buffer.
setopt hist_verify

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

#-------------------------------------------------------------------------------
# Initialisation

#-------------------------------------------------------------------------------
# Input/Output

# FLOW_CONTROL <D>
# If this option is unset, output flow control via start/stop characters (usually assigned to ^S/^Q) is disabled in the shell’s editor.
setopt noflow_control

# INTERACTIVE_COMMENTS (-k) <K> <S>
# Allow comments even in interactive shells.
setopt interactivecomments

#-------------------------------------------------------------------------------
# Job Control

# LONG_LIST_JOBS (-R)
# List jobs in the long format by default.
setopt long_list_jobs

# MONITOR (-m, ksh: -m)
# Allow job control. Set by default in interactive shells.
setopt monitor

#-------------------------------------------------------------------------------
# Prompting

# PROMPT_SUBST <K> <S>
# If set, parameter expansion, command substitution and arithmetic expansion are performed in prompts. Substitutions within prompts do not affect the command status.
setopt prompt_subst

#-------------------------------------------------------------------------------
# Scripts and Functions

#-------------------------------------------------------------------------------
# Shell Emulation

#-------------------------------------------------------------------------------
# Shell State

# INTERACTIVE (-i, ksh: -i)
# This is an interactive shell. This option is set upon initialisation if the standard input is a tty and commands are being read from standard input. (See the discussion of SHIN_STDIN.) This heuristic may be overridden by specifying a state for this option on the command line. The value of this option can only be changed via flags supplied at invocation of the shell. It cannot be changed once zsh is running.
setopt interactive

# LOGIN (-l, ksh: -l)
# This is a login shell. If this option is not explicitly set, the shell becomes a login shell if the first character of the argv[0] passed to the shell is a ‘-’.
setopt login

#-------------------------------------------------------------------------------
# Zle

# VI
# If ZLE is loaded, turning on this option has the equivalent effect of ‘bindkey -v’. In addition, the EMACS option is unset. Turning it off has no effect. The option setting is not guaranteed to reflect the current keymap. This option is provided for compatibility; bindkey is the recommended interface.
setopt vi

# ZLE (-Z)
# Use the zsh line editor. Set by default in interactive shells connected to a terminal.
setopt zle
