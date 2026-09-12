# wt - Navigate to or create git worktrees.
#
# All logic lives in the `wt` binary (crates/wt, installed by `just
# wt-install`). This wrapper exists only because a child process cannot change
# its parent shell's directory: the binary writes the directory to enter into
# the file named by --cd-file, and this function acts on it.
def --env wt [...args: string] {
    let cd_file = ([($env.TMPDIR? | default "/tmp") $"wt-cd.($nu.pid)"] | path join)
    "" | save --force $cd_file
    let rc = (try { ^wt --cd-file $cd_file ...$args; 0 } catch { $env.LAST_EXIT_CODE })
    let dest = (open --raw $cd_file | str trim)
    rm --force $cd_file
    if ($dest | is-not-empty) { cd $dest }
    if $rc != 0 { error make --unspanned { msg: $"wt exited ($rc)" } }
}
