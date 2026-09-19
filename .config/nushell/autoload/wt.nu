# wt - Navigate to or create git worktrees (nushell wrapper).
#
# All logic lives in the `wt` binary (~/.local/bin/wt). A child process
# cannot change this shell's directory, so the binary writes the target
# directory to the file named by --cd-file and this wrapper cd's to it.
# Every other action passes straight through untouched.
def --env --wrapped wt [...args] {
    let tmpdir = ($env.TMPDIR? | default "/tmp")
    let tmpdir = (if ($tmpdir | is-empty) { "/tmp" } else { $tmpdir })
    let cd_file = (^mktemp ([$tmpdir "wt-cd.XXXXXX"] | path join))
    let rc = (try { ^wt --cd-file $cd_file ...$args; 0 } catch { $env.LAST_EXIT_CODE })
    let dest = (open --raw $cd_file | str trim)
    rm --force $cd_file
    if ($dest | is-not-empty) { cd $dest }
    if $rc != 0 { error make --unspanned { msg: $"wt exited ($rc)" } }
}
