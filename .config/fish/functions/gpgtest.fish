#!/usr/bin/env fish
# gpgtest
function gpgtest --argument-names key_id passphrase
    if test -z "$key_id" #-o -z "$passphrase"
        echo "Usage: gpgtest key_id passphrase"
        return 1
    end

    echo "$password" | \
        gpg -o /dev/null \
            --local-user $key_id \
            -as - \
        and echo "The correct passphrase was entered for this key"
end
