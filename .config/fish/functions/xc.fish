function xc \
    --description='Xcode wrapper function'

    if test -f Package.swift
        echo "Opening swift package"
        open Package.swift $argv
        return
    end

    # Ignore workspaces inside xcodeproj bundle
    set -l workspaces (string match --entire --invert project.xcworkspace **.xcworkspace)
    list $workspaces | column -c 1
    if test -d $workspaces[1]
        echo "Opening first workspace"
        open $workspaces[1] $argv
        return
    end

    # Ignore CocoaPods projects
    set -l projects (string match --entire --invert Pods.xcodeproj **.xcodeproj)
    list $projects | column -c 1
    if test -d $projects[1]
        echo "Opening first project"
        open $projects[1] $argv
        return
    end

    error "No Xcode projects found in the current directory."
    return 1
end
