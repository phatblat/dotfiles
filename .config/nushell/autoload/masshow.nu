# Dependencies:
#   functions: ll
#   builtins:  which is-empty
#   externals: mas lipo

# Show which copy of mas is active: lists it with ll, lipo arch info, and mas version
export def masshow [] {
    let mas_which = (which mas)
    if ($mas_which | is-empty) { return }
    let mas_path = ($mas_which | get path | first)
    ll $mas_path
    ^lipo -info $mas_path
    ^mas version
}
