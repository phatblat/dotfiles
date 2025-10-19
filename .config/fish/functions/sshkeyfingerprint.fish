#!/usr/bin/env fish
# Show fingerprint of optional public key file, defaults to ~/.ssh/id_ed25519.pub.
function sshkeyfingerprint --argument-names file
    if test -z $file
        set file (sshkey)
        if test $status -ne 0
            # Key file not found
            return 1
        end
    end

    echo -n "[$file] "
    ssh-keygen -l -E md5 -f $file
end
