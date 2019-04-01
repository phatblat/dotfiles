function masshow \
    --description='Show which copy of mas is active'

    if not which -s mas
        return 1
    end

    ll (which mas)
    mas version
end
