function maslink \
    --description='Links debug build of mas into the path' \
    --argument-names remove

    set -l source $HOME/Library/Developer/Xcode/DerivedData/mas-aqppolouacncbpdkiaiefddzzlfq/Build/Products/Debug/mas
    set -l destination $HOME/bin/mas

    # Delete the symlink if the $remove parameter contains anything
    if test -n "$remove"
        if rm $destination
            masshow
            return
        else
            return $status
        end
    end

    if test -L $destination
        error mas is already linked at $destination
        masshow
        return 2
    end

    ln -s $source $destination
    masshow
end
