#-------------------------------------------------------------------------------
#
# cron/cron.zsh
#
# Sets up local cron based on the tracked, shared file. This is automatic
# so that I don't have to remember to reload the file on each Mac after it
# is changed
#
#-------------------------------------------------------------------------------

crontab $HOME/.dotfiles/cron/cron.file
