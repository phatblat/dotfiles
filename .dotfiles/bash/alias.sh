#-------------------------------------------------------------------------------
#
# Command-line aliases
#
#-------------------------------------------------------------------------------
# ls
alias ll="ls -l"
alias la="ls -la"
alias lA="ls -lA"
alias ld="ls -ld */" #ls -l | grep '^d'
alias lhd="la -d .*/"
alias lh="la -d .*"

alias reloadprofile="echo 'Reloading .bash_profile' && . ~/.bash_profile && git-sh"
alias viprofile="vi ~/.bash_profile && reloadprofile"
alias editprofile="mate -rw ~/.bash_profile && reloadprofile"

alias h="history"
alias tm="/Applications/TextMate.app/Contents/MacOS/TextMate"
alias ox='open *.xcodeproj'
alias ow='open *.xcworkspace'
alias chrome='open -a "Google Chrome" --args --incognito'
alias fixopenwith='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user'
alias htstatus="ps awx | grep httpd"

# burl - https://github.com/visionmedia/burl
alias GET='burl GET'
alias HEAD='burl -I'
alias POST='burl POST'
alias PUT='burl PUT'
alias PATCH='burl PATCH'
alias DELETE='burl DELETE'
alias OPTIONS='burl OPTIONS'

alias +x="exec chmod +x "

#-------------------------------------------------------------------------------
#
# Subversion
#
#-------------------------------------------------------------------------------
# alias svn='xcrun svn'
alias showsvn="find . -type d -name .svn"
# alias prunesvn="rm -rf `find . -type d -name .svn`"