#!/usr/bin/env fish
function bpi \
    --description='Run pod install through Bundler.'

    bundle exec pod install $argv
end
