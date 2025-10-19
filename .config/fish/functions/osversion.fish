#!/usr/bin/env fish
function osversion \
        --description='Prints the macOS version number'
    sw_vers -productVersion
end
