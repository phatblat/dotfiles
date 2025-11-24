# Grep environment variables
export def genv [search_term?: string] {
    if ($search_term | is-empty) {
        print "Usage: genv search_term"
        return 1
    }

    ^env | ^grep -i $search_term
}
