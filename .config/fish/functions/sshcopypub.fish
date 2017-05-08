# Copy SSH public key to general pasteboard.
function sshcopypub
    pbcopy < ~/.ssh/id_rsa.pub
end
