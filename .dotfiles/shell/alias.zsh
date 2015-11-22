#-------------------------------------------------------------------------------
#
# shell/alias.zsh
# Command-line aliases
#
#-------------------------------------------------------------------------------


# Editors

# edit
export VISUAL='/usr/local/bin/atom'
alias edit="${VISUAL}"

# e quick edit alias - with no args, opens editor to the current dir
function e() {
	if [ -z "$1" ] ; then
		edit .
	else
		edit "$*"
	fi
}

# o quick open alias - with no args, opens finder to the current dir
function o() {
	if [ -z "$1" ] ; then
		open .
	else
		# -t  Causes the given path to be opened with the default app, as determined via LaunchServices
		open -t "$*"
	fi
}

# Sublime symlink installation
alias subl_link='ln -s "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" ~/bin/subl'


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

# Profile
alias explain="alias | grep"
alias dotfiles="edit ~/.dotfiles"
alias viprofile="vi ~/.zshrc && reloadprofile"
# TODO: Figure out how to prevent PATH from growing when reloadprofile is invoked
alias reloadprofile="source ~/.zshrc"

# Shell Helpers
alias h="history"
eval $(thefuck --alias)

# OS X
alias chrome='open -a "Google Chrome" --args --incognito'
alias fixopenwith='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user'
alias icloud="cd $HOME/Library/Mobile\ Documents/com~apple~CloudDocs/"

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
