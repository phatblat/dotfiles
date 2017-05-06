# 
function pcopy
    pwd | xargs echo -n | pbcopy $argv
end

