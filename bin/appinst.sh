#!/bin/bash
# http://stackoverflow.com/questions/6682335/how-can-check-if-particular-application-software-is-installed-in-mac-os#answer-8024765

APPLESCRIPT=`cat <<EOF
on run argv
  try
    tell application "Finder"
      set appname to name of application file id "$1"
      return 0
    end tell
  on error err_msg number err_num
    return 1
  end try
end run
EOF`

retcode=`osascript -e "$APPLESCRIPT"`
exit $retcode

