#!/usr/bin/env fish
function init \
    --description='Initialize a new git repo in current or optional directory arg' \
    --argument-names dir_name

    set --local git_repo_root $(root 2>/dev/null)
    if test "$git_repo_root" = (pwd)
        error "Git repo already initialized"
        return 1
    end

    if test -n "$dir_name"
        # Create new dir for repo
        if test -f
            error "Directory already exists"
            return 2
        end

        command mkdir -p "$dir_name"
        pushd "$dir_name"
    else
        set dir_name (basename (readlink -f .))
    end

    echo dir_name $dir_name
    return

    git init
        or return $status

    if not test -f README.md
        echo "# $dir_name" > README.md
        git add README.md
        git commit -m "🎉 Initial commit"
    end

    ignore
        or return $status

    license
        or return $status

    gh repo create "$dir_name" \
        --remote phatblat \
        --public \
        --push \
        --source .
        or return $status
end
