# agy - Run agy with --project $GCP_PROJECT unless --project is passed explicitly
# GCP_PROJECT is set in ~/.env. Help and version flags pass through unchanged.
export def --wrapped agy [...args] {
    let has_project = ($args | any {|a| $a == "--project" or ($a | str starts-with "--project=") })
    let info_only = (($args | length) == 1 and ($args.0 in ["-h" "--help" "-v" "--version"]))
    if $has_project or $info_only {
        ^agy ...$args
    } else {
        if ($env.GCP_PROJECT? | default "" | is-empty) {
            error make {msg: "GCP_PROJECT is not set and --project was not given"}
        }
        ^agy --project $env.GCP_PROJECT ...$args
    }
}
