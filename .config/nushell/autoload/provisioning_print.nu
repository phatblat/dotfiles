# Dependencies:
#   functions: none
#   builtins:  path exists is-empty complete get print
#   externals: security

# Decode and print a .mobileprovision file as readable XML using security cms
export def provisioning_print [profile_path: path] {
    if ($profile_path | is-empty) {
        error make { msg: "Usage: provisioning_print path/to/profile.mobileprovision" }
    }
    if not ($profile_path | path exists) {
        error make { msg: $"($profile_path) does not exist" }
    }
    do { ^security cms -D -i $profile_path } | complete | get stdout | print
}
