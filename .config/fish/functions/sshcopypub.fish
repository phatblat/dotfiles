function sshcopypub \
        --description "Copy SSH public key to general pasteboard."
    if is_mac
        pbcopy < ~/.ssh/id_rsa.pub
    else if is_linux
        xsel --clipboard < ~/.ssh/id_rsa.pub
    end
end
