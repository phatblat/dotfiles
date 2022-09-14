# long list,show almost all,show type,human readable
function la --wraps ls
    ls -laFh $argv
end
