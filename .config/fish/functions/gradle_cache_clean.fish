#!/usr/bin/env fish
function gradle_cache_clean \
    --description='Cleans the gradle cache'

    trash  ~/.gradle/caches
end
