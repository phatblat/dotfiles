#!/usr/bin/env fish
function spotlight_disable \
    --description='Disables Spotlight indexing'

    # https://ss64.com/osx/mdutil.html
    # -a             Apply command to all stores on all volumes.
    # -i (on|off)    Turn indexing on or off.
    sudo mdutil -a -i off
end
