# gpgcopypub - Copies the public key for any GPG key found
export def gpgcopypub [] {
    let keyid = (gpgkeyid | str trim)
    let gpg_key_ascii = (^gpg --armor --export $keyid)
    $gpg_key_ascii | ^pbcopy
    print $"GPG key copied to pasteboard (keyid: ($keyid))"
}
