# 
function tracked
    git ls-tree -r --name-only HEAD $argv
end

