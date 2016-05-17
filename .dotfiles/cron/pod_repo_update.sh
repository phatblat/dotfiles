#!/bin/bash -e
#-------------------------------------------------------------------------------
#
# cron/pod_repo_update.sh
# Updates all CocoaPods spec repos
#
#-------------------------------------------------------------------------------

echo "PWD: $PWD"
which pod
bundle exec pod --version

# . $HOME/.dotfiles/cron/cron.env

bundle exec pod repo update
