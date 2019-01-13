function masshow \
    --description='Show which copy of mas is active'

    if not which -s mas
        error mas is not on the path
        return 1
    end

    ll (which mas)
    mas version
end
