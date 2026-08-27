# Searches for functions with the given string in their definition
# Usage: funky query [-C|--column|-l|--long]
export def funky [
    query: string
    --column(-C)  # Force multi-column output (default)
    --long(-l)    # List in long format
] {
    # Glob to absolute paths: ~ expansion for externals relativizes against
    # the logical cwd, but grep resolves against the physical cwd, so a
    # symlinked cwd (e.g. /tmp) makes every file "No such file or directory".
    let files = (glob ($env.HOME | path join '.config/nushell/autoload/*.nu'))

    let names = (
        ^grep $query ...$files err> /dev/null
        | lines
        | each {|line|
            $line | split row ':' | first | path basename | str replace '.nu' ''
        }
        | uniq
        | sort
    )

    if ($names | is-empty) {
        return
    }

    if $long {
        $names | str join "\n"
    } else {
        # BSD column drops the last entry when stdin lacks a trailing newline
        ($names | str join "\n") + "\n" | ^column -x
    }
}
