#!/usr/bin/env fish
# Locates a dSYM file with the given UUID.
function finddsym --wraps mdfind --argument-names uuid
    if test -z "$uuid"
        echo "Usage: finddsym uuid"
        return 1
    end

    mdfind "com_apple_xcode_dsym_uuids == <$uuid>"
end
