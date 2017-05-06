# 
function current-branch
    git rev-parse --abbrev-ref HEAD $argv
end

