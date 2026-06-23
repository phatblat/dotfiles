# Dependencies:
#   functions: none
#   builtins:  glob is-empty
#   externals: open

# Open Xcode project in the current dir
export def --wrapped ox [...rest: string] {
    let projects = (glob "*.xcodeproj")
    if ($projects | is-empty) {
        print "No .xcodeproj found in current directory"
        return
    }
    ^open ...$projects ...$rest
}
