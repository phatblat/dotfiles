#!/usr/bin/env fish
# Manage global git configuration (~/.gitconfig).
function configg
    git config --global $argv
end
