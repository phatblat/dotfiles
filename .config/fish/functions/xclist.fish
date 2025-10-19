#!/usr/bin/env fish
# Prints a clean list of paths for all installed versions of Xcode
#
# Options:
# -1 (The numeric digit 'one'.) Force output to be one entry per line. This is the default when output is not to a terminal.
function xclist --argument-names option
    set -l app_dirs /Applications ~/Applications
    set -l xcodes

    for app_dir in $app_dirs
        set xcodes $xcodes $app_dir/Xcode*.app
    end

    # One entry per line, no colors
    if not status is-interactive; or test "$option" = -1
        echo $xcodes | tr ' ' \n
        return
    end

    # Colorized output showing symlink target
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
