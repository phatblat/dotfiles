# Dependencies:
#   functions: none
#   builtins:  match str contains str trim print is-not-empty is-empty error
#   externals: none

# Toggle or set the wait flag on VISUAL or EDITOR environment variables
export def --env toggle_wait [
    state?: string  # on or off; omit to toggle current state
] {
    # using_visual = VISUAL is set to a non-empty string (mirrors zsh [[ -n "$VISUAL" ]])
    let using_visual = (($env.VISUAL? | default "") | is-not-empty)

    let s = if ($state == null or ($state | is-empty)) {
        # Detect current state
        let has_wait = if $using_visual {
            ($env.VISUAL? | default "" | str contains ($env.WAIT_FLAG? | default ""))
        } else {
            ($env.EDITOR? | default "" | str contains ($env.WAIT_FLAG? | default ""))
        }
        if $has_wait {
            print -n "Wait mode enabled, disabling"
            "off"
        } else {
            print -n "Wait mode disabled, enabling"
            "on"
        }
    } else if $state =~ '(?i)^on$' {
        "on"
    } else if $state =~ '(?i)^off$' {
        "off"
    } else {
        $state
    }

    match $s {
        "on" => {
            if not $using_visual {
                let v = $"($env.EDITOR_CLI? | default '') ($env.WAIT_FLAG_CLI? | default '')" | str trim
                $env.EDITOR = $v
                let ev = $env.EDITOR
                print $" \(EDITOR: ($ev)\)"
            } else {
                let v = $"($env.EDITOR_GUI? | default '') ($env.WAIT_FLAG_GUI? | default '')" | str trim
                $env.VISUAL = $v
                let vv = $env.VISUAL
                print $" \(VISUAL: ($vv)\)"
            }
        }
        "off" => {
            if not $using_visual {
                let v = $env.EDITOR_CLI? | default ""
                $env.EDITOR = $v
                let ev = $env.EDITOR
                print $" \(EDITOR: ($ev)\)"
            } else {
                let v = $env.EDITOR_GUI? | default ""
                $env.VISUAL = $v
                let vv = $env.VISUAL
                print $" \(VISUAL: ($vv)\)"
            }
        }
        _ => {
            error make { msg: "Usage: toggle_wait [on|off]" }
        }
    }
}
