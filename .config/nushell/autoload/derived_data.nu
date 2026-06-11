# Dependencies:
#   functions: ramdisk
#   builtins:  path exists path type print
#   externals: diskutil fileicon

# Mount a 10 GB RAM disk named DerivedData for Xcode and set a custom icon on it
export def derived_data [
    --quiet (-q)  # Suppress output
] {
    let drive_name = "DerivedData"
    let default_size = 10
    let target_path = $"/Volumes/($drive_name)"
    let icon_file = $"($env.HOME)/Pictures/Icons/Agua Onyx Icons/Onyx Media Drive.png"

    if ($target_path | path exists) and (($target_path | path type) == "dir") {
        print $"($drive_name) already mounted"
        if not $quiet {
            ^diskutil list $drive_name
        }
    } else {
        ramdisk $default_size $drive_name --quiet=$quiet
        ^fileicon set $target_path $icon_file
    }
}
