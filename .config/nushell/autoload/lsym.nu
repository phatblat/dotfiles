# Dependencies:
#   functions: none
#   builtins:  ls where
#   externals: none

# List symbolic links in the current directory
export def lsym [] {
    ls -la | where type == "symlink"
}
