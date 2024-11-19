function user \
        --description="Displays information about the current user."

    printf "%s: %s <%s> [signingKey: %s]\n" \
        $USER \
        (user.name) \
        (user.email) \
        (user.signingkey)
end
