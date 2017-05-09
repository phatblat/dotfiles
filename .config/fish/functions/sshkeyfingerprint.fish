# Show fingerprint of optional public key file, defaults to ~/.ssh/id_rsa.pub.
function sshkeyfingerprint --argument-names file
    echo file $file
    if test -z $file
        set file ~/.ssh/id_rsa.pub
    end

    echo -n "sshkeyfingerprint [$file] "
    ssh-keygen -lf $file
end
