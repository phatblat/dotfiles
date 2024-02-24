function sshserverfingerprint \
    --description 'Print fingerprint of server SSH key' \
    --argument-names hostname

    ssh-keyscan $argv[1] | ssh-keygen -lf -
end
