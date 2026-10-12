# pid - Get PID for a process name
const psgrep_nu = path self psgrep.nu
source $psgrep_nu
export def pid [name: string] {
    if ($name | is-empty) {
        error make { msg: "Usage: pid process_name" }
    }
    psgrep $name | get pid
}
