#!/bin/bash -e
#-------------------------------------------------------------------------------
#
# cron/rsync_phatblat.sh
# Syncs phatblat user dir between drives
#
#-------------------------------------------------------------------------------

. $HOME/.dotfiles/cron/cron.env
. $HOME/.dotfiles/shell/rsync.zsh      # Defines psync function

this_host=$(hostname)

# Only run this on iMac
if [[ $this_host != "imac.local" ]]; then
  exit
fi

# Sync phatblat user dir from ThunderBay -> iMac
pbsync
