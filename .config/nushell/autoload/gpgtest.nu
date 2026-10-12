# gpgtest - Test GPG key with passphrase
export def gpgtest [key_id?: string, passphrase?: string] {
    if ($key_id | is-empty) {
        error make { msg: "Usage: gpgtest key_id passphrase" }
    }
    let pw = ($passphrase | default "")
    let result = ($pw | ^gpg -o /dev/null --local-user $key_id -as - | complete)
    if $result.exit_code == 0 {
        print "The correct passphrase was entered for this key"
    }
}
