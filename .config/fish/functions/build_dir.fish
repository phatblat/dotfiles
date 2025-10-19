#!/usr/bin/env fish
function build_dir \
        --description='Displays the Xcode build dir of the current project'
    # e.g. /Users/ben/Library/Developer/Xcode/DerivedData/mas-cli-cpnrglfzdqvgargxhvgrgxzambih/Build/Products

    set --local projects $argv

    if test -z $projects
        set projects (ls -1d *.xcodeproj)
        set projects $projects (ls -1d *.xcworkspace)
    end

    for project in $projects
        set --local command
        if string match --entire .xcodeproj $project
            set command xcodebuild -project "$project" -showBuildSettings
        else if string match --entire .xcworkspace $project
            set --local scheme (xcbschemes | head -n 1)
            set command xcodebuild -workspace "$project" -scheme \'$scheme\' -showBuildSettings
        end

        eval $command \
            | grep -m 1 "BUILD_DIR" \
            | grep -oEi "\/.*"
    end
end
