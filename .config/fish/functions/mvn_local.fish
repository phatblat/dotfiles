#!/usr/bin/env fish
# https://stackoverflow.com/a/16218772
function mvn_local \
    --description='Displays path to Maven local repo'

    mvn help:evaluate \
        -Dexpression=settings.localRepository \
        | grep -v '\[INFO\]'
end
