#!/bin/bash -ex
#-------------------------------------------------------------------------------
#
# cron/gem_update.sh
# Updates all ruby gems
#
#-------------------------------------------------------------------------------

. $HOME/.dotfiles/cron/cron.env

gem_path=`which gem`
$gem_path update --system --quiet && $gem_path update --quiet
