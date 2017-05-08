# Copy SSH public key to general pasteboard.
function sshcopypub --description "Copy SSH public key to general pasteboard."
    pbcopy < ~/.ssh/id_rsa.pub
end
