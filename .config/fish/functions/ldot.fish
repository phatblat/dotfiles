# List hidden files
function ldot --wraps ls
    la -d .* $argv
end
