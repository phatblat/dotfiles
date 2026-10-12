# version - Manage version numbers for an Xcode project
export def version [
    action?: string = "*",
    market_version?: string,
    build_version?: string,
] {
    match $action {
        "build" => { version_build }
        "market" => { version_market }
        "set" => {
            if ($market_version | is-empty) {
                print "Usage: version set 1.1 123456"
                error make { msg: "version set requires market_version" }
            }

            ^agvtool new-marketing-version $market_version o> /dev/null

            if ($build_version | is-not-empty) {
                ^agvtool new-version -all $build_version o> /dev/null
            }

            version_current
        }
        "bump" => {
            let current_build = (version_build)
            ^agvtool next-version -all o> /dev/null

            # Workaround for agvtool dropping leading zeros (e.g. 010001)
            if ($current_build | str starts-with "0") {
                let new_build = (version_build)
                ^agvtool new-version -all $"0($new_build)" o> /dev/null
            }

            version_current
        }
        _ => { version_current }
    }
}
