# dsyminfo - Displays information for a Dwarf symbol file
export def --wrapped dsyminfo [file: string, ...rest: string] {
    if ($file | is-empty) {
        error make { msg: "Usage: dsyminfo path/to/dsym" }
    }
    ^dwarfdump -u $file ...$rest
}
