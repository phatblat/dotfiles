# 
function sshcopypub
    pbcopy < ~/.ssh/id_rsa.pub $argv
end

