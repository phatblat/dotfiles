# shows special submodule entries in index
function subs
    git ls-files --stage | grep 160000 $argv
end

