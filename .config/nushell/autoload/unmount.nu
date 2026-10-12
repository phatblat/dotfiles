# unmount - Unmounts a drive
export def unmount [drive_path?: string] {
    if ($drive_path | is-empty) {
        print --stderr "Usage: unmount drive_path"
        error make { msg: "unmount requires a drive_path argument" }
    }

    if not ($drive_path | path exists) {
        print --stderr $"Not found: ($drive_path)"
        error make { msg: $"Not found: ($drive_path)" }
    }

    ^hdiutil unmount $drive_path
}
