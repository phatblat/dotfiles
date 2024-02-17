function is_octodec \
    --description="Tests whether the current computer is octodec"

    string match --entire --quiet -- octodec (hostname)
end
