# Dependencies:
#   functions: none
#   builtins:  str replace str trim lines where split words get path basename print complete from match error
#   externals: xcode-select pkgutil plutil

# Display the version of the currently selected Xcode
export def xcv [
    --short(-s)   # Print only the marketing version number
] {
    let active_version = (^xcode-select -p | str trim)

    if $active_version == "/Library/Developer/CommandLineTools" {
        let pkginfo = (do { ^pkgutil --pkg-info=com.apple.pkg.DevSDK } | complete)
        let ver = if $pkginfo.exit_code == 0 {
            $pkginfo.stdout
                | lines
                | where { |l| $l | str starts-with "version:" }
                | first
                | split words
                | last
        } else {
            "unknown"
        }
        print $"($active_version) - ($ver)"
        return
    }

    let version_plist = ($active_version | str replace "Developer" "" | str trim --right --char "/" | $in + "/version.plist")

    if not ($version_plist | path exists) {
        error make { msg: $"Plist not found: ($version_plist)" }
    }

    # Use plutil to extract values as JSON for structured parsing
    let plist_json = (^plutil -convert json -o - $version_plist | from json)
    let marketing_version = ($plist_json.CFBundleShortVersionString? | default "")
    let build_version = ($plist_json.ProductBuildVersion? | default "")

    if $short {
        print $marketing_version
        return
    }

    # Map build numbers to beta labels
    let beta_version = match $build_version {
        # 10.0
        "10L176w" => "beta 1 ",
        "10L177m" => "beta 2 ",
        "10L201y" => "beta 3 ",
        "10L213o" => "beta 4 ",
        "10L221o" => "beta 5 ",
        "10L232m" => "beta 6 ",
        "10A254a" => "GM seed ",
        # 10.1
        "10O23ud" => "beta 1 ",
        "10O35n"  => "beta 2 ",
        "10O45e"  => "beta 3 ",
        # 10.2
        "10P82s"  => "beta 1 ",
        "10P91b"  => "beta 2 ",
        "10P99q"  => "beta 3 ",
        "10P107d" => "beta 4 ",
        # 11.0
        "11M336w" => "beta 1 ",
        "11M337n" => "beta 2 ",
        "11M362v" => "beta 3 ",
        "11M374r" => "beta 4 ",
        "11M382q" => "beta 5 ",
        "11M392q" => "beta 6 ",
        "11M392r" => "beta 7 ",
        "11A419c" => "GM seed 1 ",
        # 11.2
        "11B41"   => "beta 1 ",
        "11B44"   => "beta 2 ",
        # 11.2.1
        "11B53"   => "GM seed ",
        # 11.3
        "11C24b"  => "beta 1 ",
        # 11.4
        "11N111s" => "beta 1 ",
        "11N123k" => "beta 2 ",
        # 12.0
        "12A6159"  => "beta 1 ",
        "12A6163b" => "beta 2 ",
        "12A8169g" => "beta 3 ",
        "12A8179i" => "beta 4 ",
        "12A8189h" => "beta 5 ",
        "12A8189n" => "beta 6 ",
        # 12.1.1
        "12A7605b" => "RC ",
        # 12.2
        "12B5044c" => "RC ",
        # 13.0
        "13A5154h" => "beta 1 ",
        "13A5155e" => "beta 2 ",
        "13A5192j" => "beta 3 ",
        "13A5201i" => "beta 4 ",
        "13A5212g" => "beta 5 ",
        # 13.3
        "13E5086k" => "beta 1 ",
        "13E5095k" => "beta 2 ",
        "13E5104i" => "beta 3 ",
        # 14.0
        "14A5228q" => "beta 1 ",
        "14A5229c" => "beta 2 ",
        "14A5270f" => "beta 3 ",
        "14A5284g" => "beta 4 ",
        "14A5294e" => "beta 5 ",
        "14A5294g" => "beta 6 ",
        _ => "",
    }

    print $"($marketing_version) ($beta_version)\(($build_version))"
}
