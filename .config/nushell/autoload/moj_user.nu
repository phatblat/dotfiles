# moj_user - Prints an emoji for the current user
export def moj_user [] {
    let user = ($env.USER? | default "")
    match $user {
        "admin" => { print "🙆🏻‍♂️" }
        "ben" => { print "🚶" }
        "benchatelain" | "chatelain" | "zoltar" => { print "👨🏻‍🚀" }
        "phatblat" => { print "🎧" }
        "jenkins" => { print "👷🏻‍♂️" }
        _ => {
            if ($user | str starts-with "f") {
                print "🚶"
            } else {
                let first = ($user | str substring 0..0)
                print $"($first)❓"
            }
        }
    }
}
