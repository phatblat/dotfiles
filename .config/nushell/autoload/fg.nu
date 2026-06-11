# Resume a frozen job (Ctrl-Z) in the foreground, like POSIX fg
export def --env fg [id?: int] {
    if $id == null {
        job unfreeze
    } else {
        job unfreeze $id
    }
}
