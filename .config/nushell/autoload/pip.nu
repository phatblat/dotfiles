# Dependencies:
#   functions: none
#   builtins:  str trim with-env
#   externals: pip brew

# Wrapper for pip that sets CFLAGS/LDFLAGS to Homebrew include/lib paths for native extension builds
export def --wrapped pip [...rest: string] {
    let pfx = (^brew --prefix | str trim)
    with-env { CFLAGS: $"-I($pfx)/include", LDFLAGS: $"-L($pfx)/lib" } {
        ^pip ...$rest
    }
}
