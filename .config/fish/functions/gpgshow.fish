#!/usr/bin/env fish
#
function gpgshow
    gpg --list-keys \
        --keyid-format short \
        $argv
end
