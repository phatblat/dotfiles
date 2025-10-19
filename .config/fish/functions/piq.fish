#!/usr/bin/env fish
function piq \
    --description='Quiet pod install'

    pi --silent $argv
end
