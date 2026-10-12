# gpgkeyid - Prints the long format key identifiers of all GPG keys found
export def gpgkeyid [] {
    ^gpg --list-secret-keys --keyid-format short
        | ^grep -E -o "^sec.*/\\w+"
        | ^cut -d "/" -f 2
}
