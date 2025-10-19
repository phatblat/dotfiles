#!/usr/bin/env fish
function binstall \
    --description='Install Bundler with the proper bindir.'

    gem install bundler --bindir (brew_home)/bin $argv
end
