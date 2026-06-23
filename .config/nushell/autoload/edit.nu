# Dependencies:
#   functions: none
#   builtins:  which str trim is-not-empty length split row where first skip run-external
#   externals: zed void windsurf cursor code nvim vim (first found on PATH)

# Open files in the configured editor (VISUAL, then EDITOR, then first available GUI/CLI editor)
export def --wrapped edit [...rest: string] {
    # Split on whitespace so VISUAL="code --wait" becomes ["code", "--wait"]
    let editor_parts = if ($env.VISUAL? != null and ($env.VISUAL | str trim | is-not-empty)) {
        $env.VISUAL | str trim | split row ' ' | where ($it | str trim | is-not-empty)
    } else if ($env.EDITOR? != null and ($env.EDITOR | str trim | is-not-empty)) {
        $env.EDITOR | str trim | split row ' ' | where ($it | str trim | is-not-empty)
    } else {
        let candidates = ["zed", "void", "windsurf", "cursor", "code", "nvim", "vim"]
        let found = $candidates | where { |cmd| (which $cmd | length) > 0 } | first
        if ($found | is-empty) {
            error make { msg: "No editor found. Please set VISUAL or EDITOR environment variable." }
        }
        [$found]
    }
    let bin = $editor_parts | first
    let extra_flags = $editor_parts | skip 1
    run-external $bin ...$extra_flags ...$rest
}
