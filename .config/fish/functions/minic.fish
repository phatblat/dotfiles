#!/usr/bin/env fish
function minic \
        --description='SSH into mini as chatelain'
    ssh chatelain@mini.log-g.co $argv
end
