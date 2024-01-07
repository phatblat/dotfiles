function sshkey \
    --description='Find the public key file'

    if test -f ~/.ssh/id_ed25519.pub
        echo ~/.ssh/id_ed25519.pub
    else if test -f ~/.ssh/id_rsa.pub
        echo ~/.ssh/id_rsa.pub
    else
        error "No SSH key file found."
        return 1
    end
end
