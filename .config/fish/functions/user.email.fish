function user.email \
        --description="Manages the user.email git configuration setting."
    git config user.email $argv
end
