# profile_id - Extracts the UUID from a .mobileprovision profile
export def profile_id [profile: path] {
    if ($profile | is-empty) {
        error make { msg: "Usage: profile_id AppProfile.mobileprovision" }
    }
    ^grep -a -A 2 UUID $profile
    | ^grep string
    | ^sed -e 's/<string>//' -e 's/<\/string>//' -e 's/[ \t]//'
}
