# yn - Prompt the user for a yes/no response. Returns true for YES, false for NO.
export def yn [prompt: string] {
    loop {
        let answer = (input $"($prompt)> " | str downcase | str trim)
        match $answer {
            "y" | "yes" => {
                print "YES"
                return true
            }
            "n" | "no" => {
                print "NO"
                return false
            }
            _ => {}
        }
    }
}
