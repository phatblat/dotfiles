#!/usr/bin/env fish
function gwv --wraps=gw --description='Prints the version of the gradle wrapper'
    gw --version
end
