# List hidden dirs
function ldotdir --wraps ls
    ls -ad .*/ $argv
end
