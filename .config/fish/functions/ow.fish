function ow \
    --description='Opens Xcode workspace in the current or subdir'
    # Open all but project.xcworkspace
    set -l workspaces (string match --entire --invert project.xcworkspace **.xcworkspace)
    list $workspaces | column -c 1
    open $workspaces[1]
end
