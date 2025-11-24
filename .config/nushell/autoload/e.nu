# Short alias for editing a file using VISUAL or EDITOR
export def e [path?: string = "."] {
    let editor = if ($env.VISUAL? != null) { $env.VISUAL } else { $env.EDITOR }
    ^$editor $path
}
