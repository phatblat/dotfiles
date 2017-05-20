# Detects a clean work tree.
function git_repo_clean
    not git_repo_dirty
end
