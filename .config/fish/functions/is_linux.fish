function is_linux \
    --description="Tests whether the current computer is running Linux"

    test "$KERNEL" = "Linux"
end
