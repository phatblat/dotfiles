function console_user \
        --description="Tests whether the current user logged into the console (GUI)"
    if is_mac
        test $USER = (stat -f '%Su' /dev/console)
    else if is_linux
        test $USER = (stat --format='%U' /tmp/.X11-unix/X0)
    else
        error Unknown kernel: $KERNEL
        return 1
    end
end
