
# null
function gpgkeyid
    gpg --list-keys --keyid-format long | egrep -o "^pub.*/\w+" | cut -d "/" -f 2
end
