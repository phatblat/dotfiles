# This will return multiple 8-char values if there are multiple secret keys.
function gpgkeyid --description='Prints the long format key identifiers of all GPG keys found.'
    gpg --list-secret-keys \
            --keyid-format short \
        | egrep -o "^sec.*/\w+" \
        | cut -d "/" -f 2
end
