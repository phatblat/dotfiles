#-------------------------------------------------------------------------------
#
# cron/rsync_phatblat.sh
# Syncs phatblat user dir between drives
#
#-------------------------------------------------------------------------------

. $HOME/.dotfiles/cron/cron.env
. $HOME/.dotfiles/shell/rsync.sh      # Defines sync function

# Sync user dir from iMac -> ThunderBay
time sync $phatblat_imac $phatblat_external
