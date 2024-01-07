function sshcopypub \
    --description "Copy SSH public key to pasteboard/clipboard."

    # Find the public key file
    set --local key_file (sshkey)

    # Copy the key
    if is_mac
        pbcopy <$key_file
    else if is_linux
        xsel --clipboard <$key_file
    end
end
