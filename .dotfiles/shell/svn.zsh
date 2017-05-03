#-------------------------------------------------------------------------------
#
# shell/svn.zsh
# Subversion aliases
#
#-------------------------------------------------------------------------------

lj info 'shell/svn.zsh'

alias showsvn="find . -type d -name .svn"
#alias prunesvn="rm -rf `showsvn`"
alias prunesvn="find . -type d -name .svn -exec rm -rf {} \;"
