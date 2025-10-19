#!/usr/bin/env fish
# Enables developer mode.
function developer_mode
    DevToolsSecurity -status
    sudo DevToolsSecurity -enable $argv
end
