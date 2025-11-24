# Searches for functions with the given string in their definition
export def funky [
    query: string
    --column(-C)  # Force multi-column output
    --long(-l)    # List in long format
] {
    let results = (^grep $query ~/.config/nushell/autoload/*.nu | lines)

    if ($results | is-empty) {
        return
    }

    let funcs = (
        $results
        | each { |line|
            let path = ($line | split row ':' | first)
            let file_name = ($path | path basename)
            $file_name | str replace '.nu' ''
        }
        | uniq
        | sort
    )

    if $long {
        $funcs | each { |f| print $f }
    } else {
        # Column output (default)
        $funcs | wrap name | table --expand
    }
}
