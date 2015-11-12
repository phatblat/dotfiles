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

# burl - https://github.com/visionmedia/burl
alias GET='burl GET'
alias HEAD='burl -I'
alias POST='burl POST'
alias PUT='burl PUT'
alias PATCH='burl PATCH'
alias DELETE='burl DELETE'
alias OPTIONS='burl OPTIONS'


#-------------------------------------------------------------------------------
#
# Unix
#
#-------------------------------------------------------------------------------
function fixperms() {
	find "$1" -type f -print -exec chmod 644 {} \;
	find "$1" -type d -print -exec chmod 755 {} \;
}


#-------------------------------------------------------------------------------
#
# Subversion
#
#-------------------------------------------------------------------------------
alias showsvn="find . -type d -name .svn"
#alias prunesvn="rm -rf `showsvn`"
alias prunesvn="find . -type d -name .svn -exec rm -rf {} \;"
