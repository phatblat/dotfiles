#!/usr/bin/env fish
# long list,sorted by date,show type,human readable
function lt --wraps ls
    ls -otFh $argv
end
