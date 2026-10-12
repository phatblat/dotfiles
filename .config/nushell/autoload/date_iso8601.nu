# date_iso8601 - Prints date in ISO-8601 format
export def date_iso8601 [format: string = "timezone"] {
    match $format {
        "s" | "sh" | "short" => {
            ^date "+%Y-%m-%d"
        }
        "z" | "gmt" => {
            ^date -u "+%Y-%m-%dT%H:%M:%SZ"
        }
        _ => {
            ^date "+%Y-%m-%dT%H:%M:%S%z"
        }
    }
}
