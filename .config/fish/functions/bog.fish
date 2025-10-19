#!/usr/bin/env fish
function bog \
    --description='Update gem bundle using the local Gemfile.'

    bo --gemfile=Gemfile
end
