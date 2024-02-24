function is_console_user \
    --description "Tests whether the current user is logged into the console (GUI)"

    test $USER = (console_user)
end
