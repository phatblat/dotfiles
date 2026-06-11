# Dependencies:
#   functions: none
#   builtins:  str trim print
#   externals: hdiutil diskutil

# Create a macOS RAM disk of a given size (GB) and format it as HFS+
export def ramdisk [
    disk_size: int        # Size in gigabytes
    drive_name?: string   # Volume name (defaults to RAMDisk_<size>GB)
    --quiet (-q)          # Suppress the "RAM disk created" confirmation message
] {
    let name = if ($drive_name == null or ($drive_name | is-empty)) {
        $"RAMDisk_($disk_size)GB"
    } else {
        $drive_name
    }

    # 1 block = 512 bytes; 1 MB = 2048 blocks; 1 GB = 1024 MB
    let memory_blocks = $disk_size * 1024 * 2048

    let hdiutil_output = (^hdiutil attach -nomount $"ram://($memory_blocks)" | str trim)

    # A failing external throws immediately in nushell; no exit code check needed.
    ^diskutil erasevolume HFS+ $name $hdiutil_output

    if not $quiet {
        print $"RAM disk created with ($disk_size) GB"
    }
}
