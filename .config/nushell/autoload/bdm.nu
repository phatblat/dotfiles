# Dependencies:
#   functions: current_branch
#   builtins:  none
#   externals: git

const current_branch_nu = path self current_branch.nu
source $current_branch_nu

# bdm - Delete local branches which have been merged into the current branch, always preserving master and main
export def bdm [] {
    let keep = [master main (current_branch)]
    ^git branch --format='%(refname:short)' --merged
    | lines
    | where $it not-in $keep
    | each {|b| ^git branch -d $b }
    | ignore
}
