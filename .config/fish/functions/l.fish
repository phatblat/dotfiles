# List files showing size,show type,human readable
function l --wraps ls
    ls -lFh $argv
end
