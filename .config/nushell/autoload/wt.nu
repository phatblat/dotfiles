# wt - Navigate to or create git worktrees (nushell wrapper).
#
# All logic lives in the `wt` binary (~/.local/bin/wt). A child process
# cannot change this shell's directory, so the binary writes the target
# directory to the file named by --cd-file and this wrapper cd's to it.
# Every other action passes straight through untouched.
def --env --wrapped wt [...args] {
    let cd_file = (^mktemp -t wt-cd)
    do -i { ^/Users/phatblat/.local/bin/wt --cd-file $cd_file ...$args }
    let dest = (open --raw $cd_file | str trim)
    rm $cd_file
    if ($dest | is-not-empty) { cd $dest }
}
