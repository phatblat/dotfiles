function is_mac \
    --description="Tests whether the current computer is running macOS"

    test "$KERNEL" = Darwin
end
