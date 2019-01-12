function maslink \
    --description='Links debug build of mas into the path' \
    --argument-names remove

    set -l source $HOME/Library/Developer/Xcode/DerivedData/mas-aqppolouacncbpdkiaiefddzzlfq/Build/Products/Debug/mas
    set -l destination $HOME/bin/mas

    # Delete the symlink if the $remove parameter contains anything
    if test -n "$remove"
        rm $destination
        return $status
    end

    if test -L $destination
        error mas is already linked to $destination
        return 1
    end

    ln -s $source $destination
    ll (which mas)
end
