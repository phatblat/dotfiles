#-------------------------------------------------------------------------------
#
# alias.zsh
# Command-line aliases
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

# Profile
alias reloadprofile="source ~/.zshrc"
alias viprofile="vi ~/.zshrc && reloadprofile"
alias editprofile="subl -rw ~/.reloadprofile && reloadprofile"
alias explain="alias | grep"

alias h="history"
alias chrome='open -a "Google Chrome" --args --incognito'
alias fixopenwith='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user'

# Xcode
alias ox='open *.xcodeproj'
alias ow='open *.xcworkspace'

# CocoaPods
alias pi='pod install --no-repo-update'

# Tower
alias tower='gittower .'

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

# Boxen
alias boxendir='pushd /opt/boxen/repo'

#-------------------------------------------------------------------------------
#
# Editors
#
#-------------------------------------------------------------------------------

# -t  Causes the file to be opened with the default text editor, as determined via LaunchServices
alias edit='open -t'

# Sublime
alias subl_link='ln -s "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" ~/bin/subl'

# Atom
EDITOR="atom -w"
function e() {
	if [ "$1" == "" ] ; then
	  exec ${EDITOR} .
	else
	  exec ${EDITOR} "$1"
	fi
}

# Marked
function mark() {
    if [ "$1" ] ; then
        open -a Marked.app "$1"
    else
        open -a Marked.app
    fi
}

#-------------------------------------------------------------------------------
#
# SSH
#
#-------------------------------------------------------------------------------
alias sshcopypub='pbcopy < ~/.ssh/id_rsa.pub'

function sshkeyfingerprint() {
	if (($+1)); then
		ssh-keygen -lf "$1"
	else
		ssh-keygen -lf ~/.ssh/id_rsa.pub
	fi
}

function sshnewkey() {
	if (($+1)); then
		ssh-keygen -t rsa -C "$1"
	else
		echo "Usage: sshnewkey user@host"
	fi
}

#-------------------------------------------------------------------------------
#
# Unix
#
#-------------------------------------------------------------------------------
function fixperms() {
	find "$1" -type f -print -exec chmod 644 {} \;
	find "$1" -type d -print -exec chmod 755 {} \;
}
