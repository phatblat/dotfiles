# Adds lines to .gitignore
export def ignore [...patterns: string] {
    let root = (^git rev-parse --show-toplevel | str trim)
    let gitignore = ($root | path join '.gitignore')

    touch $gitignore

    let file_size = (ls $gitignore | get size | first)
    mut ignore_list = []
    mut commit_message = ""

    if $file_size > 0b {
        # Read current ignores, filter out empty lines
        $ignore_list = (open $gitignore | lines | where $it != "")
    } else {
        # Seed with standard ignores
        $ignore_list = (ignores)
        $commit_message = "chore: add standard ignores"
        print "Creating .gitignore"
    }

    if ($patterns | length) > 0 {
        $ignore_list = ($patterns | append $ignore_list)
        $commit_message = $"chore: ignore ($patterns | str join ' ')"
    }

    # Write all patterns and sort unique
    $ignore_list | uniq | sort | save --force $gitignore

    if ($commit_message | is-empty) {
        print "Nothing new added to ignores, just sorted and removed duplicates."
        return
    }

    ^git add $gitignore
    ^git commit -m $commit_message
}
