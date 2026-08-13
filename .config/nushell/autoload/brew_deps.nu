# Dependencies:
#   functions: none
#   builtins:  lines where is-empty each
#   externals: brew

# List dependencies of installed Homebrew packages as a structured list
export def brew_deps [...args: string] {
    ^brew deps --tree --installed ...$args
        | lines
        | where {|l| not ($l | is-empty) }
        | each {|l| {dependency: $l} }
}
