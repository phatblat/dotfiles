# gpgtest - Test GPG key with passphrase
# The passphrase is read from the argument or prompted for (hidden), and is
# handed to gpg on fd 0 (loopback pinentry) while signing an empty file, so it
# is the passphrase being tested rather than the message.
export def gpgtest [key_id?: string, passphrase?: string] {
    if ($key_id | is-empty) {
        error make { msg: "Usage: gpgtest key_id [passphrase]" }
    }
    let pw = if ($passphrase | is-empty) { input --suppress-output "Passphrase: " } else { $passphrase }
    # gpg's stderr is shown and a non-zero exit aborts before the success message
    $pw | ^gpg --batch --pinentry-mode loopback --passphrase-fd 0 -o /dev/null --local-user $key_id -as /dev/null
    print "The correct passphrase was entered for this key"
}
