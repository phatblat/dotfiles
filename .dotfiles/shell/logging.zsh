#-------------------------------------------------------------------------------
#
# shell/logging.zsh
# Logging for dotfiles
#
#-------------------------------------------------------------------------------

lj info 'shell/logging.zsh'

mkdir -p /usr/local/var/log/lj
lj --file /usr/local/var/log/lj/lumberjack.log --level debug
