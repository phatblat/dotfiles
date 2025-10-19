#!/usr/bin/env fish
function repo_new \
    --description='Creates a new GitHub repo using the local dir as the root' \
    --argument-names repo_name

    if test -z $repo_name
        echo 'Usage: repo_new [repo_name]'
        return 1
    end

    gh repo create $repo_name --public --source=.
    pborigin
    pp
end
