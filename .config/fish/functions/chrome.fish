#!/usr/bin/env fish
# Launch Google Chrome.
#
# When Chrome is launched via this function the 1Password extension reports
#
# > Browser could not be verified.
#
function chrome
    open -a "Google Chrome" --args --new-window $argv
end
