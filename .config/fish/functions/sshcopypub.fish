function sshcopypub \
    --description "Copy SSH public key to pasteboard/clipboard."

    set --local key_file

    # Find the public key file
    if test -f ~/.ssh/id_ed25519.pub
        set key_file ~/.ssh/id_ed25519.pub
    else if test -f ~/.ssh/id_rsa.pub
        set key_file ~/.ssh/id_rsa.pub
    else
        error "No SSH key file found."
        return 1
    end

    # Copy the key
    if is_mac
        pbcopy < $key_file
    else if is_linux
        xsel --clipboard < $key_file
    end
end
