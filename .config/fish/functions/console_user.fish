function console_user \
    --description="Prints the username of the user logged into the console (GUI)"

    if is_mac
        # stock mac args: -f '%Su'
        # coreutils args: --format='%U'
        stat --format='%U' /dev/console
    else if is_linux
        stat --format='%U' /tmp/.X11-unix/X0
    else
        error Unknown kernel: $KERNEL
        return 1
    end
end
