# Dependencies:
#   functions: current_branch
#   builtins:  none
#   externals: git

const current_branch_nu = path self current_branch.nu
source $current_branch_nu

# bdm - Delete local branches which have been merged into the current branch, always preserving master and main
export def bdm [] {
    let keep = [master main (current_branch)]
    ^git for-each-ref --merged HEAD --format='%(refname:short)' refs/heads
    | lines
    | where $it not-in $keep
    | each {|b| do -i { ^git branch -d $b } }
    | ignore
}
