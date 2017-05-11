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
            # Symlinks are magenta
            echo (set_color magenta)$xcode_path(set_color normal)" -> "$link_target
        else
            # Directories are blue
            echo (set_color blue)$xcode_path(set_color normal)
        end
    end
end
