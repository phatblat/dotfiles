function is_mac \
        --description="Tests whether the current computer is running macOS"
    return test $KERNEL == "Darwin"
end
