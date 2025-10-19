#!/usr/bin/env fish
# Check for existence of a function.
function fq --argument-names function_name
    set -l file ~/.config/fish/functions/$function_name.fish

    functions --query $function_name
    or test -e $file
end
