#!/usr/bin/env fish
function sshcopypub \
    --description "Copy SSH public key to pasteboard/clipboard."

    set --local key_file

    set key_file (sshkey)
    if test $status -ne 0
        # Key file not found
        return 1
    end

    # Copy the key
    if is_mac
        pbcopy < $key_file
    else if is_linux
        xsel --clipboard < $key_file
    end
end
