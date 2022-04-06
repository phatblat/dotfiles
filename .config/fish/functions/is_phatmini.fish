function is_phatmini \
    --description="Tests whether the current computer is phatmini"

    string match --entire --quiet -- "phatmini" (hostname)
end
