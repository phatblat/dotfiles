#!/usr/bin/env fish
function lga \
    --description='Pretty history graph showing all'

    git log \
        --all \
        --graph \
        --abbrev-commit \
        --date=relative \
        --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' \
        $argv
end
