# email_url - Determines an appropriate contact for a given url
export def email_url [url?: string] {
    let user = "ben"
    let work_org = "getditto"
    let work_domain = "ditto.com"
    let default = $"($user)@octop.ad"

    if ($url | is-empty) {
        return $default
    }

    if ($url | str contains $work_org) {
        $"($user)@($work_domain)"
    } else {
        $default
    }
}
