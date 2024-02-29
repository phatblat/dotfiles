function is_linux \
    --description "Tests whether the current OS is Linux"

    test (uname) = Linux
end
