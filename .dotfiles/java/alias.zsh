#-------------------------------------------------------------------------------
#
# java/alias.zsh
# Java Aliases
#
#-------------------------------------------------------------------------------

lj info 'java/alias.zsh'

alias whichjdk='/usr/libexec/java_home'
alias showjdks='/usr/libexec/java_home -V'

alias setJdk6='export JAVA_HOME=$(/usr/libexec/java_home -v 1.6)'
alias setJdk7='export JAVA_HOME=$(/usr/libexec/java_home -v 1.7)'
alias setJdk8='export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)'
