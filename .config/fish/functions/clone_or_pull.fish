# Clones a fresh copy or pulls an existing git repo.
function clone_or_pull --argument-names folder_name git_url branch
    if test -z "$folder_name" -o -z "$git_url"
        echo "Usage: clone_or_pull folder url [branch]"
        return 1
    end

    if not test -d $folder_name
        git clone "$git_url" $folder_name

        # Checkout branch
        if test -n "$branch"
            pushd $folder_name
            git checkout $branch
            popd
        end
    else
        pushd $folder_name
        if test -n "$branch" -a "$branch" != (current_branch)
            echo "WARNING: $folder_name currently has the "(current_branch) \
                " branch checked out (!=$branch)"
        end
        git pull
        popd
    end
end
