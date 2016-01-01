#-------------------------------------------------------------------------------
#
# shell/alias.zsh
# Miscellaneous command-line aliases
#
#-------------------------------------------------------------------------------

# ls
alias lsa="ls -a"
alias ll="ls -l"
alias la="ls -la"
alias lA="ls -lA"
alias ld="ls -ld */" #ls -l | grep '^d'
alias lhd="la -d .*/"
alias lh="la -d .*"

# Help
bashman () { man bash | less -p "^       $1 "; }
alias bashman=bashman

# Shell Helpers
alias h="history"
eval $(thefuck --alias)

# OS X
alias chrome='open -a "Google Chrome" --args --incognito'
alias fixopenwith='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user'
# Tower
alias tower='gittower .'

# Dropbox
alias dropboxfinderreset='pluginkit -e use -i com.getdropbox.dropbox.garcon'

# Web
alias xconf='vi /usr/local/etc/nginx/nginx.conf'
alias xstart='sudo nginx'
alias xreload='sudo nginx -s reload'
alias xquit='sudo nginx -s stop'
alias htstatus="ps awx | grep httpd"
alias gen="bundle exec rake generate && \
	terminal-notifier -group 'octopress' -title 'Octopress' \
		-message \"Done generating \$(basename \$(pwd))\" \
		-activate 'com.apple.Safari'"
alias deploy="bundle exec rake deploy"


#-------------------------------------------------------------------------------
#
# Unix
#
#-------------------------------------------------------------------------------
function fixperms() {
	find "$1" -type f -print -exec chmod 644 {} \;
	find "$1" -type d -print -exec chmod 755 {} \;
}

# Renames the first argument, either appending ".bak" or stripping that extension
# if already present.
# - $1 - The file or folder to rename
function bak {
	if [[ ! -a "$1" ]]; then
		echo "'$1' does not exist"
		return 1
	fi

	# > h
	# >      Remove a trailing pathname component, leaving the head.  This
	# >      works like `dirname'.
	# >
	# > r
	# >      Remove a filename extension of the form `.XXX', leaving the root
	# >      name.
	# >
	# > e
	# >      Remove all but the extension.
	# >
	# > t
	# >      Remove all leading pathname components, leaving the tail.  This
	# >      works like `basename'.
	# http://www.zsh.org/mla/users/2006/msg00239.html
	if [[ "${1:e}" == "bak" ]]; then
		# Remove the .bak extension
		mv "$1" "${1:r}"
		echo "Renamed to '${1:r}'"
	else
		# Append a .bak extension
		mv "$1" "$1.bak"
		echo "Renamed to '$1.bak'"
	fi
}
