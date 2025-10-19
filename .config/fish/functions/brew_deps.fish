#!/usr/bin/env fish
function brew_deps \
    --description='Lists dependencies of brew packages.'

    brew deps --tree --installed $argv
end
