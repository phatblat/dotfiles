# Dependencies:
#   functions: none
#   builtins:  path exists print is-not-empty complete get
#   externals: open find

# Open the Xcode workspace, project, or Package.swift in the current directory
export def xc [...rest: string] {
    if ("Package.swift" | path exists) {
        print "Opening swift package"
        ^open Package.swift ...$rest
        return
    }

    # Find workspaces (ignore ones inside xcodeproj bundle)
    let workspaces = (
        do { ^find . -name "*.xcworkspace" -not -path "*/project.xcworkspace*" } | complete | get stdout
        | lines
        | where { |p| ($p | str trim | is-not-empty) }
    )
    if ($workspaces | length) > 0 {
        print ($workspaces | str join "\n")
        let first_ws = ($workspaces | first)
        if ($first_ws | path exists) {
            print "Opening first workspace"
            ^open $first_ws ...$rest
            return
        }
    }

    # Find projects (ignore CocoaPods projects)
    let projects = (
        do { ^find . -name "*.xcodeproj" -not -name "Pods.xcodeproj" } | complete | get stdout
        | lines
        | where { |p| ($p | str trim | is-not-empty) }
    )
    if ($projects | length) > 0 {
        print ($projects | str join "\n")
        let first_proj = ($projects | first)
        if ($first_proj | path exists) {
            print "Opening first project"
            ^open $first_proj ...$rest
            return
        }
    }

    error make { msg: "No Xcode projects found in the current directory." }
}
