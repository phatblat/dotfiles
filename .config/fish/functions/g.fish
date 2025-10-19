#!/usr/bin/env fish
function g --wraps='gradle' --description='Gradle alias'
    gradle $argv
end
