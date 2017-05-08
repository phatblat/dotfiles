# List symbolic links.
function lsym
    la $argv | grep '^l'
end
