#!/usr/bin/env fish
function gbe \
    --description='Shows Gradle build environment'

    gw buildEnvironment $argv
end
