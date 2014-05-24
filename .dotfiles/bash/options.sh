# If the shell is bash, grep will succeed with 0 (false)
echo $SHELL | grep -qE "bash"
if [[ ! $? ]] ; then
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

fi # end bash

export EDITOR='subl -w'
