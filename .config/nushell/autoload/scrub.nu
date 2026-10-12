# scrub - Deletes the given path and removes it from all git commits
export def scrub [delete_path: string] {
    if ($delete_path | is-empty) {
        error make { msg: "Usage: scrub <delete_path>" }
    }

    let answer = (input $"Are you sure you want to delete ($delete_path) and scrub that path from git history? [y/N] ")

    match $answer {
        "y" | "yes" | "Y" | "YES" => { print "YES" }
        _ => {
            print "NO"
            return
        }
    }

    ^git filter-branch --force --index-filter $"git rm -r --force --cached --ignore-unmatch ($delete_path)" --prune-empty --tag-name-filter cat -- --all
}
