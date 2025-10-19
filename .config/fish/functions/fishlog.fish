#!/usr/bin/env fish
function fishlog
    eval less /tmp/fishd.log.$USER
end
