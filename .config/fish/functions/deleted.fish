function deleted \
    --description='Lists files deleted from git history.'

    git log --diff-filter=D --summary
end
