#-------------------------------------------------------------------------------
#
# Bash command-line customization
#
#-------------------------------------------------------------------------------
# VI-style prompt editing
set -o vi

export HISTCONTROL=ignoredups:erasedups
export HISTSIZE=10000
shopt -s histappend
## reedit a substitution line if it failed
shopt -s histreedit
## edit a recalled history line before executing
shopt -s histverify

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

#-------------------------------------------------------------------------------
#
# Subversion
#
#-------------------------------------------------------------------------------
alias svn='xcrun svn'
alias showsvn="find . -type d -name .svn"
# alias prunesvn="rm -rf `find . -type d -name .svn`"


#-------------------------------------------------------------------------------
#
# iOS development
#
#-------------------------------------------------------------------------------
SIMDIR=~/Library/Application\ Support/iPhone\ Simulator/6.1/Applications/
function simdir {
    cd "$SIMDIR"
}
export CODESIGN_ALLOCATE="/Applications/Xcode.app/Contents/Developer/usr/bin/codesign_allocate"

# Fortify
FORTIFY_PATH=~/dev/fortify/HP_Fortify_SCA_and_Apps_3.60_Mac_x64


#-------------------------------------------------------------------------------
#
# GCC stuff
#
#-------------------------------------------------------------------------------
#export ARCHFLAGS="-arch x86_64"
#export LIBRARY_PATH=/usr/include
# export MACOSX_DEPLOYMENT_TARGET=10.6
# export CFLAGS="-I/usr/local/include:/usr/include -arch x86_64 -isysroot /Developer/SDKs/MacOSX10.6.sdk"
# export CFLAGS="-I/usr/local/include:/usr/include -isysroot /Developer/SDKs/MacOSX10.6.sdk"
#export CFLAGS="-arch i686 -isysroot /Developer/SDKs/MacOSX10.5.sdk"
#export CFLAGS="-arch x86_64 -isysroot /Developer/SDKs/MacOSX10.5.sdk"
#export CFLAGS="-arch x86_64 -g -Os -pipe -no-cpp-precomp"
#export CCFLAGS="-arch x86_64 -g -Os -pipe"
#export CXXFLAGS="-arch x86_64 -g -Os -pipe"
#export LDFLAGS="-arch x86_64 -bind_at_load"
# export LDFLAGS=-L/lib
# export CXXFLAGS=$CFLAGS
# export CPPFLAGS=$CXXFLAGS
# export ACLOCAL_FLAGS="-I /share/aclocal"


#-------------------------------------------------------------------------------
#
# PATH building
#
#-------------------------------------------------------------------------------
#
# Python
#
export PYTHONPATH=/Library/Python/2.6/site-packages/

#
# ImageMagick
#
#export IMAGEMAGICK_HOME=/usr/local/imagemagick

# TextMate SVN
# http://wiki.macromates.com/Main/SubversionCheckout
export LC_CTYPE=en_US.UTF-8
# If you get an error "svn: Can't recode string", then you may need to unset the LC_ALL environment variable:
# export LC_ALL=

export ANDROID_SDK_ROOT=/Applications/adt-bundle-mac/sdk
ANDROID_PATH=${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/tools

#
# Node path
#
export NODE_PATH=/usr/local/lib/node_modules

#
# System path
#
#echo $PATH

# Manually setting the original OS X path so that reloadprofile won't keep growing the PATH
OSX_PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/X11/bin:/usr/X11R6/bin

# Prepend user bin dir to PATH
export PATH=~/bin:/usr/local/bin:${ANDROID_PATH}:${FORTIFY_PATH}/bin:${OSX_PATH}

#echo $PATH


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

function git_branch {
    ref=$(git symbolic-ref HEAD 2> /dev/null) || return
    echo -n ${ref#refs/heads/}
}

function parse_git_branch {
    ref=$(git symbolic-ref HEAD 2> /dev/null) || return
    echo " ("$(git_branch)")"
}

PS1="\[$COLOR_LIGHT_GRAY\]\$(date +%H:%M) \[$COLOR_RED\]\w\[$COLOR_YELLOW\]\$(parse_git_branch)\[$COLOR_GREEN\] \[$COLOR_CYAN\]$ \[$COLOR_NC\]"

#PS1='\h:\W \u\$ '
# PS1="[\w]\n\$ "
# PS1=">>>\$ "


#-------------------------------------------------------------------------------
#
# git + hub
#
#-------------------------------------------------------------------------------
export EDITOR='mate -w'
eval "$(hub alias -s)"


#-------------------------------------------------------------------------------
#
# Heroku
#
#-------------------------------------------------------------------------------
if [ -f ~/heroku/.herokurc ]; then
   source ~/heroku/.herokurc
fi


#-------------------------------------------------------------------------------
#
# RBENV
#
#-------------------------------------------------------------------------------
export RBENV_ROOT=/usr/local/var/rbenv
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi


#-------------------------------------------------------------------------------
#
# Local customizations, loaded last
#
#-------------------------------------------------------------------------------
if [ -f ~/.bash_profile.local ]; then
   source ~/.bash_profile.local
fi
