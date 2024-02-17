# Deletes the given path and removes it from all git commits.
function scrub --argument-names delete_path
    if test -z $delete_path
        echo "Usage: scrub <delete_path>"
        return 1
    end

    get --prompt "Are you sure you want to delete $delete_path and scrub that path from git history?" \
        --default="y" \
        | read -l should_delete

    switch $should_delete
        case y yes
            echo YES
        case n no
            echo NO
            return 1
    end

    git filter-branch --force --index-filter \
        "git rm -r --force cached --ignore-unmatch $delete_path" \
        --prune-empty --tag-name-filter cat -- --all
end
