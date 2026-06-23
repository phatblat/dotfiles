# Dependencies:
#   functions: none
#   builtins:  str contains str starts-with split row str substring print
#   externals: hostname

# Print an emoji representing the current hostname
export def moj_host [] {
    let full_host = (^hostname | str trim)
    let host = if ($full_host | str contains ".") {
        $full_host | split row "." | get 0
    } else {
        $full_host
    }
    match $host {
        "DTO-A017" => { print "💻" }
        "phatmini" | "co-mac1" => { print "🖥" }
        "m1" | "mini" => { print "⌨️" }
        "hacklet" | "penguin" | "pocket3" | "pop-os" => { print "🐧" }
        _ => {
            if ($host | str starts-with "labtop") {
                print "🐧"
            } else {
                let first_char = $full_host | str substring 0..0
                print $"($first_char)❓"
            }
        }
    }
}
