# pid - Get PID for a process name
export def pid [name: string] {
    if ($name | is-empty) {
        error make { msg: "Usage: pid process_name" }
    }
    psgrep $name | get pid
}
