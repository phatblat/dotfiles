# brew_versions - Lists installed versions of a formula
export def brew_versions [formula: string] {
    if ($formula | is-empty) {
        error make { msg: "Usage: brew_versions formula" }
    }
    let installed = (do { ^brew list $formula } | complete)
    if $installed.exit_code != 0 {
        error make { msg: $"($formula) is not installed." }
    }
    # brew list --versions ruby output:
    # ruby 2.3.3 2.4.1_1
    ^brew list --versions $formula | ^cut -d' ' -f2-
}
