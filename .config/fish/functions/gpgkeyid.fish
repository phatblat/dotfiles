# Prints the long format key identifiers of all GPG keys found.
function gpgkeyid
    gpg --list-keys --keyid-format long \
        | egrep -o "^pub.*/\w+" \
        | cut -d "/" -f 2 $argv
end
