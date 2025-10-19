#!/usr/bin/env fish
# Short alias for executing Fastlane through Bundler.
function bef
    bundle exec "fastlane $argv"
end
