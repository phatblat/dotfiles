# Dependencies:
#   functions: none
#   builtins:  str trim
#   externals: gem brew

# Install Bundler with the proper bindir set to the Homebrew prefix bin
export def binstall [...rest: string] {
    let bindir = (^brew --prefix | str trim) + "/bin"
    ^gem install bundler --bindir $bindir ...$rest
}
