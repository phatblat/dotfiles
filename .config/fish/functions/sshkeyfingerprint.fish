function sshkeyfingerprint \
    --description='Show fingerprint of optional public key file.' \
    --argument-names key_file

    if test -z $key_file
        set key_file (sshkey)
    end

    echo -n "[$key_file] "
    ssh-keygen -l -E md5 -f $key_file
end
