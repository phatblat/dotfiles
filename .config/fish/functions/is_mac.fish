function is_mac \
    --description "Tests whether the current OS is macOS"

    test (uname) = Darwin
end
