#-------------------------------------------------------------------------------
#
# crontab/crontab.zsh
#
# Sets up local crontab based on the tracked, shared file. This is automatic
# so that I don't have to remember to reload the file on each Mac after it
# is changed
#
#-------------------------------------------------------------------------------

crontab $HOME/.dotfiles/crontab/crontab.file
