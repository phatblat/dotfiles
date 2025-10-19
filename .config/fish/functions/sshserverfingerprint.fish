#!/usr/bin/env fish
function sshserverfingerprint \
    --description='Print fingerprint of server SSH key' \
    --argument-names host_name

    ssh-keyscan $argv[1] | ssh-keygen -lf -
end
