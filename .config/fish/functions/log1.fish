function log1 --description='Alias for git log.'
    git log -1 --pretty=fuller $argv
end
