#!/bin/bash -e
#-------------------------------------------------------------------------------
#
# cron/pod_repo_update.sh
# Updates CocoaPods trunk spec repo
#
#-------------------------------------------------------------------------------

# shellcheck source=cron.env
source "$HOME/.dotfiles/cron/cron.env"

bundle install --quiet
bundle exec pod repo update trunk --silent
