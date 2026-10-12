# func - Prints the source of a loaded function
export def func [name?: string] {
    if ($name | is-empty) {
        error make { msg: "Usage: func name" }
    }
    view source $name
}
