# Dependencies:
#   functions: none
#   builtins:  each error first is-empty lines match print skip str where
#   externals: launchctl sudo

# Control the macOS Screen Sharing service (com.apple.screensharing), the VNC
# service behind System Settings > General > Sharing > Screen Sharing. This is
# not Remote Management (Apple Remote Desktop): that is a separate service
# driven by ARDAgent's kickstart tool and is deliberately left alone here.
#
#   screen_sharing              same as `screen_sharing status`
#   screen_sharing status       print the launchd override state for the service
#   screen_sharing enable       enable the service and load it now (sudo)
#   screen_sharing disable      disable the service and unload it now (sudo)
#   screen_sharing restart      restart the service (sudo)
#
# Arguments after the subcommand are appended to the launchctl call that
# performs the action (bootstrap, bootout, kickstart, print-disabled).
export def --wrapped screen_sharing [...args] {
    let service = "system/com.apple.screensharing"
    let daemon_plist = "/System/Library/LaunchDaemons/com.apple.screensharing.plist"
    let subcommand = if ($args | is-empty) { "status" } else { $args | first }
    let rest = if ($args | is-empty) { [] } else { $args | skip 1 }

    match $subcommand {
        # The persistent override is written first in both directions: if the
        # load/unload step fails, the service is still in the requested state
        # after the next boot.
        "enable" => {
            ^sudo launchctl enable $service
            ^sudo launchctl bootstrap system $daemon_plist ...$rest
        }
        "disable" => {
            ^sudo launchctl disable $service
            ^sudo launchctl bootout $service ...$rest
        }
        "restart" => {
            ^sudo launchctl kickstart -k $service ...$rest
        }
        "status" => {
            let overrides = (
                ^launchctl print-disabled system ...$rest
                | lines
                | where {|line| $line | str contains '"com.apple.screensharing"' }
                | each {|line| $line | str trim }
            )
            if ($overrides | is-empty) {
                print '"com.apple.screensharing" => disabled (no launchd override)'
            } else {
                print ($overrides | str join (char newline))
            }
        }
        _ => {
            error make --unspanned {
                msg: $"screen_sharing: unknown subcommand '($subcommand)' \(expected: enable, disable, restart, status)"
            }
        }
    }
}
