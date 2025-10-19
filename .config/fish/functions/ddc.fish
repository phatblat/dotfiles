#!/usr/bin/env fish
function ddc \
    --description='Docker deep clean'

    # Prune containers
    dcp

    # Prune volumes
    dvp

    # Prune images
    dip

    # Prune networks
    dnp
end
