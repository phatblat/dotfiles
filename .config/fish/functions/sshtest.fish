#!/usr/bin/env fish
function sshtest \
    --description='Tests SSH connection to GitHub.'
    ssh -T git@github.com
end
