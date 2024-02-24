function tracking \
    --description 'Display tracking information for the current branch.'

    git rev-parse --abbrev-ref --symbolic-full-name @{u} $argv
end
