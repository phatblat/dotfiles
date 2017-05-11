# Print path to all installed copies of Xcode.
function xcodes
    set -l app_dirs /Applications ~/Applications

    for app_dir in $app_dirs
        for app in $app_dir/Xcode*
            ls -od $app
        end
    end
end
