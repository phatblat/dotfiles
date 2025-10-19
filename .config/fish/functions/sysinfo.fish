#!/usr/bin/env fish
# Print system info
function sysinfo
    uname -a
    sw_vers -productVersion
    system_profiler SPSoftwareDataType
end
