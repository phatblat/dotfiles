function ignore \
        --argument-names new_ignore \
        --description='Adds lines to .gitignore'

    set -l gitignore (root)/.gitignore
    set -l ignore_list
    set -l commit_message

    if test -f $gitignore -a (filesize $gitignore) -ne 0
        set ignore_list (cat $gitignore)
    else
        # Seed the list with standard ignores
        set ignore_list (ignores)
        set commit_message "Standard ignores"
        echo "Creating .gitignore"
    end

    if test -n "$new_ignore"
        set ignore_list $new_ignore $ignore_list
        set commit_message "Ignore $new_ignore"
    end

    for pattern in $ignore_list
        echo $pattern >> $gitignore
    end

    sort --unique --output=$gitignore $gitignore

    if test -z "$commit_message"
        echo "Nothing new added to ignores, just sorted and removed duplicates."
        return
    end

    git add $gitignore
    git commit -m $commit_message
end

