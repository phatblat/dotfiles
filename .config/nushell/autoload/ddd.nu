# Dependencies:
#   functions: none
#   builtins:  path exists path type print rm is-empty
#   externals: none

# Delete the Xcode DerivedData directory pointed to by $DERIVED_DATA
export def ddd [] {
    if ($env.DERIVED_DATA? == null or ($env.DERIVED_DATA? | is-empty)) {
        print --stderr "DERIVED_DATA is not set"
        exit 1
    }

    let dir = $env.DERIVED_DATA
    if ($dir | path exists) and (($dir | path type) == "dir") {
        print $"Deleting derived data directory ($dir)"
        rm --recursive --force $dir
    } else {
        print "Derived data directory does not exist"
    }
}
