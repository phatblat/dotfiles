#!/bin/sh
#
# git-plist-filter.sh
# https://gist.github.com/WIZARDISHUNGRY/94750
#
# had to do this because git doesn't like attaching stdin and out to plutil (waitpid error)

#TMPDIR isn't set for ssh logins!
TMPDIR=`getconf DARWIN_USER_TEMP_DIR`

tempfoo=`basename $0`
TMPFILE=`mktemp ${TMPDIR}/${tempfoo}.XXXXXX` || exit 1

cat > $TMPFILE
plutil -convert xml1 $TMPFILE
cat $TMPFILE
rm $TMPFILE
