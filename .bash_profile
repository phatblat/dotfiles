# Bash command-line customization

# VI-style prompt editing
set -o vi

export HISTCONTROL=ignoredups:erasedups
export HISTSIZE=10000
shopt -s histappend
## reedit a substitution line if it failed
shopt -s histreedit
## edit a recalled history line before executing
shopt -s histverify

#
# Command-line aliases
#
# ls
alias ll="ls -l"
alias la="ls -la"
alias lA="ls -lA"
alias ld="ls -ld */" #ls -l | grep '^d'
alias lhd="la -d .*/"
alias lh="la -d .*"

# git-sh secondary aliases
function bmv() { mv $@; }
function brm() { rm $@; }

alias reloadprofile="echo 'Reloading .bash_profile' && . ~/.bash_profile"
alias viprofile="vi ~/.bash_profile && reloadprofile"
alias mateprofile="mate -rw ~/.bash_profile && reloadprofile"
alias editprofile=mateprofile

alias h="history"
alias tm="/Applications/TextMate.app/Contents/MacOS/TextMate"
alias ox='open *.xcodeproj/'

alias htstatus="ps awx | grep httpd"

######################################
#
# VCS specific functions & aliases
#
######################################

#
# vcs_which
# Determines whether the current directory is a SVN working copy or Mercurial repository
#
function vcs_which {
    if [ -d .svn ]; then
        cmd=svn
    else
        if [ -d .hg ]; then
            cmd=hg
        else
            echo The current dir is not a working copy or repository
        fi
    fi
}
#
# vcs_status
# Displays the current status
#
function vcs_status {
    vcs_which; $cmd status "$@";
}
alias s="vcs_status"
#
# vcs_info
# Displays working copy info
#
function vcs_info {
    vcs_which; $cmd info "$@";
}
alias i="vcs_info"
#
# vcs_log
# Displays the last 5 log entries
#
function vcs_log {
    vcs_which; $cmd log -v -l 5;
}
alias l="vcs_log"
#
# vcs_add
# Displays the current status
#
function vcs_add {
    vcs_which;
    if [ $cmd == svn ]; then
        $cmd add "$@";
    fi
    if [ $cmd == hg ]; then
        $cmd addremove;
    fi
}
alias a="vcs_add"
#
# vcs_diff
# Diffs modified files
#
function vcs_diff {
    vcs_which; $cmd diff "$@";
}
alias d="vcs_diff"
#
# vcs_diff_tm
# Diffs modified files using TextMate
#
function vcs_diff_tm {
    vcs_which; $cmd diff --diff-cmd mate "$@";
}
alias dtm="vcs_diff_tm"
#
# vcs_diff+fm
# Diffs modified files using FileMerge
#
function vcs_diff_fm {
    vcs_which; $cmd diff --diff-cmd fmdiff "$@";
}
alias dfm="vcs_diff_fm"
# Convenience functions
dm () {
    vcs_which; d > ~/tmp/temp.diff; mate ~/tmp/temp.diff;
}
#
# vcs_commit
# Commits modified files
#
function vcs_commit {
    vcs_which; $cmd commit "$@";
}
alias c="vcs_commit"
#
# vcs_update
# Updates working copy from repo
#
function vcs_update {
    vcs_which; $cmd update "$@";
}
alias u="vcs_update"
#
# vcs_revert
# Reverts file to the head state from repo
#
function vcs_revert {
    vcs_which;
    if [ $cmd == svn ]; then
        $cmd revert "$@";
    fi
    if [ $cmd == hg ]; then
        $cmd revert "$@" --no-backup
    fi
}
alias r="vcs_revert"

#
# GCC stuff
#
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

#
# Java
#
#export JAVA_HOME=/Library/Java/Home
#export JRE_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/CurrentJDK/Home
#export CLASSPATH=.:/System/Library/Frameworks/JavaVM.framework/Versions/CurrentJDK/Classes/classes.jar:/usr/local/tomcat/lib/servlet-api.jar
export JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/1.6/Home
export JDK_HOME="/Library/Java/Home"
export ANT_HOME=/usr/share/ant
export ANT_OPTS="-Xms256M -Xmx512M"
export MVN_HOME=/usr/local/maven #apache-maven-3.0.2 @ 2011-01-17
#export TOMCAT_HOME=/Applications/NetBeans/apache-tomcat-6.0.16
#export CATALINA_HOME=/usr/local/tomcat
export JBOSS_HOME=/usr/local/jboss
export JMETER_HOME=/usr/local/jmeter


#
# Scala
#
export SCALA_HOME=/usr/local/scala

#
# Git
#
export GIT_EDITOR='mate -w'

#
# Google Go
#
export GOROOT=$HOME/Dev/Go
export GOOS=darwin
export GOARCH=amd64

#
# Python
#
export PYTHONPATH=/Library/Python/2.6/site-packages/

#
# MySQL
#
export MYSQL_HOME=/usr/local/mysql

#
# Subversion
#
# export SVN_HOME=/opt/subversion
export SVN_EDITOR='mate -w'

#
# NPM (node package manager) modules
#
export NODE_PATH='/usr/local/lib/node_modules'

#
# ActiveMQ
#
export ACTIVEMQ_HOME=/usr/local/activemq

#
# ImageMagick
#
#export IMAGEMAGICK_HOME=/usr/local/imagemagick

# TextMate SVN
# http://wiki.macromates.com/Main/SubversionCheckout
export LC_CTYPE=en_US.UTF-8
# If you get an error "svn: Can't recode string", then you may need to unset the LC_ALL environment variable:
# export LC_ALL=

export ANDROID_SDK_ROOT=/usr/local/Cellar/android-sdk/r16

#
# Node path
#
export NODE_PATH=/usr/local/lib/node_modules

#
# System path
#

#echo $PATH

# Manually setting the original OS X path so that reloadprofile won't keep growing the PATH
OSX_PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/X11/bin:/usr/X11R6/bin

export PATH=~/bin:$OSX_PATH

export PATH=$JAVA_HOME/bin:$PATH
export PATH=$ANT_HOME/bin:$PATH
export PATH=$MVN_HOME/bin:$PATH
export PATH=$JBOSS_HOME/bin:$PATH
export PATH=$JMETER_HOME/bin:$PATH
export PATH=$SCALA_HOME/bin:$PATH
export PATH=$MYSQL_HOME/bin:$PATH
# export PATH=$SVN_HOME/bin:$PATH
export PATH=$ACTIVEMQ_HOME/bin:$PATH

export PATH=$ANDROID_SDK_ROOT/tools:$ANDROID_SDK_ROOT/platform-tools:$PATH

export PATH=~/bin:$OSX_PATH:$PATH

#echo $PATH
#
# END: PATH
#

# Terminal colors
# http://stackoverflow.com/questions/1355976/bash-on-snow-leopard-doesnt-obey-terminal-colours
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

###################################
#
# Prompt customization
#
###################################
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
# Heroku
#
if [ -f ~/heroku/.herokurc ]; then
   source ~/heroku/.herokurc
fi

#-------------------------------------------------------------------------------
# Add RVM to PATH for scripting
PATH=$PATH:$HOME/.rvm/bin

# This loads RVM into a shell session.
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

#-------------------------------------------------------------------------------
# Load local customizations last
if [ -f ~/.bash_profile.local ]; then
   source ~/.bash_profile.local
fi
