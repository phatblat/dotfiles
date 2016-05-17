#!/bin/bash -e
#-------------------------------------------------------------------------------
#
# cron/dotfiles_fetch.sh
# Performs a `git fetch` on dotfiles repo
#
#-------------------------------------------------------------------------------

. $HOME/.dotfiles/cron/cron.env

git_path=`which git`
pushd $HOME > /dev/null 2>&1

$git_path fetch --quiet

popd > /dev/null 2>&1
