# Dependencies:
#   functions: none
#   builtins:  str trim is-empty
#   externals: gem brew

# Install a Ruby gem with --force, placing the binary in the Homebrew prefix bin directory
export def gem_install [gem_name: string, ...rest: string] {
    if ($gem_name | is-empty) {
        error make { msg: "Usage: gem_install gem_name ..." }
    }
    let bindir = (^brew --prefix | str trim) + "/bin"
    ^gem install --force $gem_name --bindir $bindir ...$rest
}
