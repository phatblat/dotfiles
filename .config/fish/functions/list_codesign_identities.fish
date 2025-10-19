#!/usr/bin/env fish
# 
function list_codesign_identities
    security find-identity -v -p codesigning $argv
end
