# Dependencies:
#   functions: none
#   builtins:  error is-empty match
#   externals: open ls

# Open System Settings, optionally to a named pane (use "list" to see available panes)
export def prefs [pref_pane?: string] {
    let panes_path = "/System/Library/PreferencePanes/"

    if $pref_pane == null or ($pref_pane | is-empty) {
        ^open -b com.apple.systempreferences
        return
    }

    if $pref_pane == "list" {
        ^ls $panes_path
        return
    }

    let pane = match $pref_pane {
        "k" | "kb" | "keyboard"   => "Keyboard",
        "s" | "sec" | "security"  => "Security",
        _                         => $pref_pane,
    }

    ^open -b com.apple.systempreferences $"($panes_path)($pane).prefPane"
}
