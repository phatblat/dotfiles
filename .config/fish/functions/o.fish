#!/usr/bin/env fish
# Short alias for open.
function o --wraps open --argument-names path
    if test -z $path
        open .
    else
        # -t  Causes the given path to be opened with the default app, as determined via LaunchServices
        open -t $argv
    end
end
