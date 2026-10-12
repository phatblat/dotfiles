# gpgcopypub - Copies the public key for any GPG key found
const gpgkeyid_nu = path self gpgkeyid.nu
source $gpgkeyid_nu
export def gpgcopypub [] {
    let keyid = (gpgkeyid | str trim)
    let gpg_key_ascii = (^gpg --armor --export $keyid)
    $gpg_key_ascii | ^pbcopy
    print $"GPG key copied to pasteboard (keyid: ($keyid))"
}
