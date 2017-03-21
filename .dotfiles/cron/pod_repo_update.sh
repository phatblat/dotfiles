#!/bin/bash -e
#-------------------------------------------------------------------------------
#
# cron/pod_repo_update.sh
# Updates all CocoaPods spec repos
#
#-------------------------------------------------------------------------------

. $HOME/.dotfiles/cron/cron.env

bundle install --quiet
bundle exec pod repo update master --silent
