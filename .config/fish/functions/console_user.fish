function console_user \
    --description "Prints the username of the user logged into the console (GUI)"

    if is_mac
        fileowner /dev/console
    else if is_linux
        fileowner /tmp/.X11-unix/X0
    else
        error Unknown kernel: $KERNEL
        return 1
    end
end
