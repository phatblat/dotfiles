# 
function gpgshow
    gpg --list-keys --keyid-format long $argv
end

