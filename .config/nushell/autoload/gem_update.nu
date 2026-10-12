# gem_update - Update a Ruby gem at the system level (requires sudo permissions)
export def gem_update [gem_name?: string, ...rest: string] {
    if ($gem_name | is-empty) {
        error make { msg: "Usage: gem_update gem_name ..." }
    }
    let bindir = (^brew --prefix | str trim) + "/bin"
    ^gem update --force $gem_name --bindir $bindir ...$rest
}
