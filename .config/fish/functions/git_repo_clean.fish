function git_repo_clean \
    --description='Detects a clean work tree.'

    # Count returns non-zero when no arguments are passed to it (clean repo)
    not count (git status --porcelain) >/dev/null
end
