# Dependencies:
#   functions: none
#   builtins:  print is-empty str trim lines where length
#   externals: brew trash

# Install and test a Homebrew formula from source
export def brew_test [token: string, formula_version?: string] {
    if ($token | is-empty) {
        error make { msg: "Usage: brew_test token [formula_version]" }
    }

    # Special handling for certain formulae
    match $token {
        "mas" => {
            let pinned = (^brew tap --list-pinned | lines | where { |l| ($l | str trim) == "mas-cli/tap" })
            if (($pinned | length) > 0) {
                ^brew tap-unpin mas-cli/tap
            }
            ^trash ~/Library/Caches/org.carthage.CarthageKit
        }
        _ => {}
    }

    let installed = (do { ^brew ls --versions $token } | complete)
    if $installed.exit_code == 0 {
        ^brew uninstall $token
    }

    ^brew install --build-from-source $token
    ^brew test $token
    ^brew audit --strict $token
}
