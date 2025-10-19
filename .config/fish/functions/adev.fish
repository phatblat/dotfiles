#!/usr/bin/env fish
function adev \
    --description='Open the Apple Developer portal news page.'

    open https://developer.apple.com/news/releases/ $argv
end
