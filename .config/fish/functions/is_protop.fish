function is_protop \
    --description "Tests whether the current computer is protop"

    string match --entire --quiet -- protop (hostname)
end
