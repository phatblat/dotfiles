#!/usr/local/bin/fish
function git-plist-filter --description 'Converts plist data to XML format (stdin->stdout).'
    #!/bin/sh
    # had to do this because git doesn't like attaching stdin and out to plutil (waitpid error)

    #TMPDIR isn't set for ssh logins!
    set -l TMPDIR (getconf DARWIN_USER_TEMP_DIR)
    set -l function_name git-plist-filter

    set TMPFILE (mktemp $TMPDIR/$function_name.XXXXXX)

    # Drop stdin to temp file
    cat >$TMPFILE
    plutil -convert xml1 $TMPFILE
    cat $TMPFILE
    rm $TMPFILE
end
