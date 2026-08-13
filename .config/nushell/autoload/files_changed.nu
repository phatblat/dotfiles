# Dependencies:
#   functions: none
#   builtins:  error is-empty
#   externals: git

# List files changed since a treeish
export def files_changed [tree1: string, tree2?: string] {
    if ($tree1 | is-empty) {
        error make { msg: "Usage: files_changed tree1 [tree2]" }
    }
    if $tree2 != null {
        ^git diff --name-status $tree1 $tree2
    } else {
        ^git diff --name-status $tree1
    }
}
