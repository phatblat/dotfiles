#!/usr/bin/env fish
# sorted by date,recursive,show type,human readable
function lr --wraps ls
    ls -tRFh $argv
end
