# Dependencies:
#   functions: none
#   builtins:  none
#   externals: git

# Detects whether $PWD is inside a git repo or not
export def git_inside_repo []: nothing -> bool {
    (^git rev-parse --is-inside-work-tree out+err>| complete | get exit_code) == 0
}
