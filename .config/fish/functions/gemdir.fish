#!/usr/bin/env fish
function gemdir \
        --description='Prints the path to the system gem dir'
    ruby -r rubygems -e 'puts Gem.dir'
end
