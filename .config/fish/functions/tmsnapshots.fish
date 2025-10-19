#!/usr/bin/env fish
function tmsnapshots \
    --description='List Time Machine Snapshots'

    tmutil listlocalsnapshots /
end
