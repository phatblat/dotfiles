# Print path to all installed copies of Xcode.
function xcodes
    set app_dirs \
        "/Applications" \
        "$HOME/Applications" \
        "/Volumes/Thunderbay/Applications"

    for app_dir in $app_dirs
        for app in $app_dir/Xcode*
            ls -ld $app
        end
    end
end
