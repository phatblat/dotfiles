# Dependencies:
#   functions: ramdisk
#   builtins:  path exists print
#   externals: diskutil fileicon

# Mount a CargoTarget RAM disk and set CARGO_TARGET_DIR to it
export def --env cargo_target [
    --quiet (-q)   # Suppress output
] {
    source /Users/phatblat/.config/nushell/autoload/ramdisk.nu

    let drive_name = "CargoTarget"
    let target_path = $"/Volumes/($drive_name)"
    let icon_file = $"($env.HOME)/Pictures/Icons/rustacean-flat-happy.webp"

    let output = if ($target_path | path exists) {
        $"($drive_name) already mounted"
    } else {
        ramdisk 50 $drive_name --quiet
        if ($icon_file | path exists) {
            ^fileicon set $"/Volumes/($drive_name)" $icon_file
        }
        $"($drive_name) mounted at ($target_path)"
    }

    $env.CARGO_TARGET_DIR = $target_path

    if not $quiet {
        print $output
    }
}
