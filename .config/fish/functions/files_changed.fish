function files_changed \
    --description='Shows files changed since a treeish' \
    --argument-names tree1 tree2

    if test -z $tree1
        echo 'Usage: files_changed tree1 [tree2]'
        return 1
    end

    git diff --name-status $tree1 $tree2
end
