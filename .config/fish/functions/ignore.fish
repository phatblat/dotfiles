function ignore \
    --description 'Adds lines to .gitignore'

    set -l gitignore (root)/.gitignore
    set -l ignore_list
    set -l commit_message

    touch $gitignore

    if test (filesize $gitignore) -ne 0
        # Read in current ignores
        set ignore_list (cat $gitignore)
    else
        # Seed the list with standard ignores
        set ignore_list (ignores)
        set commit_message "🙈 Standard ignores"
        echo "Creating .gitignore"
    end

    if test -n "$argv"
        set ignore_list $argv $ignore_list
        set commit_message "🙈 Ignore $argv"
    end

    for pattern in $ignore_list
        echo $pattern >>$gitignore
    end

    sort --unique --output=$gitignore $gitignore

    if test -z "$commit_message"
        echo "Nothing new added to ignores, just sorted and removed duplicates."
        return
    end

    git add $gitignore
    git commit -m $commit_message
end
