function fetch \
    --description='Fetch branch from the default git remote'

    git fetch --prune $argv
end
