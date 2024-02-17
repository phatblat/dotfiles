function git_repo_dirty \
    --description='Detects a dirty work tree.'

    not git_repo_clean
end
