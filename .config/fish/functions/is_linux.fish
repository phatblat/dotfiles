function is_mac \
        --description="Tests whether the current computer is running Linux"
    test $KERNEL = "Linux"
end
