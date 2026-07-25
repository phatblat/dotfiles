# Resume a frozen job (Ctrl-Z) in the foreground, like POSIX fg
# Resolves the job id from `job list` instead of relying on bare `job unfreeze`,
# whose cached last-frozen id goes stale (nushell/nushell#16561)
export def --env fg [id?: int] {
    let target = if $id != null {
        $id
    } else {
        let frozen = job list | where type == "frozen" | get id
        if ($frozen | is-empty) {
            error make {msg: "no frozen jobs"}
        }
        $frozen | last
    }
    job unfreeze $target
}
