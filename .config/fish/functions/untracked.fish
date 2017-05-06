# 
function untracked
    git ls-files --others --exclude-standard $argv
end

