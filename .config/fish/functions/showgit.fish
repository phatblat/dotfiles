function showgit \
    --description='Searches for .git repos recursively below the current dir'
    find . -type d -name .git $argv
end
