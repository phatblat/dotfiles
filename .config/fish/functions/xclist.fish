# Prints a clean list of paths for all installed versions of Xcode
function xclist
    set -l app_dirs /Applications ~/Applications
    set -l xcodes

    for app_dir in $app_dirs
        set xcodes $xcodes $app_dir/Xcode*.app
    end

    for xcode_path in $xcodes
        set -l link_target (readlink $xcode_path)
        if test -n "$link_target"
            echo "$xcode_path -> $link_target"
        else
            echo $xcode_path
        end
    end
end
