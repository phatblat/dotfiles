# Prints a clean list of paths for all installed versions of Xcode
function xclist
    set -l app_dirs /Applications ~/Applications
    set -l xcodes

    for app_dir in $app_dirs
        set xcodes $xcodes $app_dir/Xcode*.app
    end

    for xcode_version in $xcodes
        string replace '.app' '' (basename $xcode_version)
    end
end
