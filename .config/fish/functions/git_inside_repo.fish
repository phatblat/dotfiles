# Detects whether $PWD is inside a git repo or not. Exit code is 0 for yes, 128
# for no.
function git_inside_repo --argument-names arg1
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
end
