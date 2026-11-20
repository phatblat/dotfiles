# agy - Run agy with --project $GCP_PROJECT unless --project is passed explicitly
export def --wrapped agy [...args] {
    let has_project = ($args | any {|a| $a == "--project" or ($a | str starts-with "--project=") })
    if $has_project {
        ^agy ...$args
    } else {
        if ($env.GCP_PROJECT? | default "" | is-empty) {
            error make {msg: "GCP_PROJECT is not set and --project was not given"}
        }
        ^agy --project $env.GCP_PROJECT ...$args
    }
}
