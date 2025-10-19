#!/usr/bin/env fish
function xtest --description='Validate nginx config'
    sudo nginx -t $argv
end
