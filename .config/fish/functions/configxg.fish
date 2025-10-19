#!/usr/bin/env fish
# Manage extended global git configuration ($XDG_CONFIG_HOME/git/config -> ~/.config/git/config).
function configxg
    set -l global_config ~/.config/git/config
    git config --file $global_config $argv
end
