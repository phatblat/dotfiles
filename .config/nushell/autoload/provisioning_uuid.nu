# provisioning_uuid - Prints the UUID from a provisioning profile
export def provisioning_uuid [profile_path: path] {
    if ($profile_path | is-empty) {
        error make { msg: "Usage: provisioning_uuid path/to/profile.mobileprovision" }
    }
    provisioning_print $profile_path
    | ^grep UUID -A 1
    | ^tail -n 1
    | ^cut -d ">" -f 2
    | ^cut -d "<" -f 1
}
