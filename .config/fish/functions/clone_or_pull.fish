# Clones a fresh copy or pulls an existing git repo.
function clone_or_pull --argument-names folder_name git_url
    if test -z folder_name -o -z git_url
        echo "Usage: clone_or_pull folder url"
        return 1
    end

    if not test -e $folder_name
        git clone "$git_url" $folder_name
    else
        pushd $folder_name
        git pull
        popd
    end
end
