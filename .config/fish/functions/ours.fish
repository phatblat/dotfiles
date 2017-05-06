# 
function ours
    git checkout --ours $@ && git add $@ $argv
end

