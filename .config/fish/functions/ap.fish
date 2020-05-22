function ap \
    --description='Selectively add some of the modifications in the work tree to the git staging area.'

    git add --patch $argv
end
