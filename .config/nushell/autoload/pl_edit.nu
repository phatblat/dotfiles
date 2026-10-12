# pl_edit - Edit Powerline config files
const psgrep_nu = path self psgrep.nu
source $psgrep_nu
export def pl_edit [] {
    print "Kill the powerline-daemon (-k) to see changes."
    psgrep powerline-daemon | print
    let editor_parts = ($env.EDITOR? | default "vim" | str trim | split row ' ' | where ($it | str trim | is-not-empty))
    let bin = $editor_parts | first
    let extra_flags = $editor_parts | skip 1
    run-external $bin ...$extra_flags ($env.HOME | path join ".config" "powerline")
}
