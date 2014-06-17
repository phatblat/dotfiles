#-------------------------------------------------------------------------------
#
# options.sh
# Command-line options
#
#-------------------------------------------------------------------------------
# bash-only options

# VI-style prompt editing
set -o vi

export HISTCONTROL=ignoredups:erasedups
export HISTSIZE=10000
shopt -s histappend
## reedit a substitution line if it failed
shopt -s histreedit
## edit a recalled history line before executing
shopt -s histverify

export EDITOR='subl -w'
