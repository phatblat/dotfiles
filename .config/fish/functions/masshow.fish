#!/usr/bin/env fish
function masshow \
    --description='Show which copy of mas is active'

    if not type -q mas
        return 1
    end

    set -l path (which mas)
    ll $path
    lipo -info $path
    mas version
end
