function masshow \
    --description 'Show which copy of mas is active'

    if not type --query mas
        return 1
    end

    set -l path (which mas)
    ll $path
    lipo -info $path
    mas version
end
