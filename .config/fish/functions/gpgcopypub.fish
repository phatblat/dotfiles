#!/usr/bin/env fish
# Copies the public key for any GPG key found.
function gpgcopypub
    set -l keyid (gpgkeyid)
    set -l gpg_key_ascii (gpg --armor --export $keyid)
    list $gpg_key_ascii \
        | pbcopy
    echo "GPG key copied to pasteboard (keyid: $keyid)"
end
