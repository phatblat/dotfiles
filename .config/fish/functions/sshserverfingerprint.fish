function sshserverfingerprint \
    --description='Print fingerprint of server SSH key' \
    --argument-names hostname

    ssh-keyscan $hostname | ssh-keygen -lf -
end
