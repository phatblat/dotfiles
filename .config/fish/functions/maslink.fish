function maslink \
    --description='Links debug build of mas into the path' \
    --argument-names remove

    set -l derived_data $HOME/Library/Developer/Xcode/DerivedData
    set -l folder_name

    switch (hostname)
    case tredecim
        set folder_name mas-gbyvetvfnsdaiigwwzwjvnbutabs
    case greymatter
        set folder_name mas-gbyvetvfnsdaiigwwzwjvnbutabs
    case octodec
        set folder_name mas-aqppolouacncbpdkiaiefddzzlfq
    case '*'
        error "This device is not set up for this command. Add the mas folder to the maslink function."
        ls $derived_data
        return 1
    end

    # Xcode GUI puts binary here
    set -l source $derived_data/$folder_name/Build/Products/Debug/mas
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
