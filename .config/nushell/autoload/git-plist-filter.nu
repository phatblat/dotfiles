# git-plist-filter - Converts plist data to XML format (stdin->stdout)
# Had to do this because git doesn't like attaching stdin and out to plutil (waitpid error).
export def git-plist-filter [] {
    let tmpdir = ($env.TMPDIR? | default "/tmp")
    let tmpfile = (^mktemp $"($tmpdir)/git-plist-filter.XXXXXX" | str trim)
    $in | save --force --raw $tmpfile
    ^plutil -convert xml1 $tmpfile
    open --raw $tmpfile
    ^rm $tmpfile
}
