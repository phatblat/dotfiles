#!/usr/bin/env fish
function dtc
    git difftool --cached $argv
end
