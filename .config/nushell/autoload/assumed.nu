# assumed - List files in the current repo for which changes are ignored
export def assumed [] {
    ^git ls-files -v
    | lines
    | where ($it | str starts-with "h ")
    | each {|l| $l | str substring 2.. }
}
