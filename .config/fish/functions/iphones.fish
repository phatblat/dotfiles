#!/usr/bin/env fish
function iphones \
    --description 'Show connected iOS devices'


    system_profiler SPUSBDataType | sed -n -E -e '/(iPhone|iPad)/,/Serial/s/ *Serial Number: *(.+)/\1/p'
end
