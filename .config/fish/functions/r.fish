# Interactive rebase for the last few commits, count specified as 1st arg (default: 10).
function r --argument-names count
    if test -z $count
        set count 10
    end

    git rebase --interactive HEAD~$count
end
