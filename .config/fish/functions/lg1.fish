#!/usr/bin/env fish
function lg1 \
    --description='Pretty history graph with one commit'

    set -l commit_count 1
    set -l format '%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'

    git log \
        -$commit_count \
        --graph \
        --abbrev-commit \
        --date=relative \
        --pretty=format:$format \
        $argv
end
