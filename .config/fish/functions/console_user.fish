function console_user \
        --description="Tests whether the current user logged into the console (GUI)"
    test $USER = (stat -f '%Su' /dev/console)
end
