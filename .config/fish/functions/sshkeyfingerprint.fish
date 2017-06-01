# Show fingerprint of optional public key file, defaults to ~/.ssh/id_rsa.pub.
function sshkeyfingerprint --argument-names file
    if test -z $file
        set file ~/.ssh/id_rsa.pub
    end

    echo -n "[$file] "
    ssh-keygen -l -E md5 -f $file
end
