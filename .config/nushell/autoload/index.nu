# index - Prints the 1-based index of a value in a list
export def index [value?: string, ...items: string] {
    if ($value | is-empty) {
        error make { msg: "Usage: index value $list" }
    }
    let matches = ($items | enumerate | where item == $value)
    if ($matches | is-empty) {
        error make { msg: $"($value) not found" }
    }
    ($matches | first | get index) + 1
}
