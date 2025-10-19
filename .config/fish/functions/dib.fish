#!/usr/bin/env fish
function dib \
    --description='Build an image from a Dockerfile'

    docker image build $argv
end
