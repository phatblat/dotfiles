#-------------------------------------------------------------------------------
#
# shell/svn.zsh
# Subversion aliases
#
#-------------------------------------------------------------------------------

alias showsvn="find . -type d -name .svn"
#alias prunesvn="rm -rf `showsvn`"
alias prunesvn="find . -type d -name .svn -exec rm -rf {} \;"
