function ra \
        --description 'Adds a git remote' \
        --argument-names name url
    if test -z $name
        error Remote name required
        return 1
    end

    # Add a fork of the project with only the remote name is given.
    if test -z $url
        set -l remote_url (git remote get-url (remote_for_current_branch))
        # Drop scheme and host
        set -l path (string split ':' $remote_url)[2]
        # Drop .git
        set -l path (string split '.' $path)[1]
        set -l project (string split '/' $path)[2]
        set url "git@github.com:$name/$project.git"
    end

    git remote add $name $url
    and rv
    and fetch $name
end
