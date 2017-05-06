#-------------------------------------------------------------------------------
#
# shell/logging.zsh
# Logging for dotfiles
#
#-------------------------------------------------------------------------------

LUMBERJACK_LOGS=/usr/local/var/log/lj
mkdir -p $LUMBERJACK_LOGS
chmod g+w $LUMBERJACK_LOGS

lj --file $LUMBERJACK_LOGS/lumberjack.$USER.log --level debug

lj info 'shell/logging.zsh'
