# Detects a dirty work tree.
function git_repo_dirty
    # Count returns non-zero when no arguments are passed to it (clean repo)
    count (git status --porcelain) >/dev/null
end
