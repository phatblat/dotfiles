# 
function sortdiff
    git diff "$@" | grep "^[+-]" | sort --key=1.2 | uniq -u -s1 $argv
end

