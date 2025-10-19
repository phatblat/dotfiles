#!/usr/bin/env fish
function ida \
    --description='Lauch IDA with elevated priveleges'

    set -l ida_path "/Applications/IDA Pro 7.5"

    if not test -d "$ida_path"
        error 'IDA is not installed'
        return 1
    end

    sudo $ida_path/idabin/ida64 $argv
end
