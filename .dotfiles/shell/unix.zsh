#-------------------------------------------------------------------------------
#
# shell/unix.zsh
# Miscellaneous Unix aliases
#
#-------------------------------------------------------------------------------

# members function - lists all members of the given group
# Usage: members $group
function members {
  dscl . -list /Users | while read user
  do printf "$user "
    dsmemberutil checkmembership -U "$user" -G "$*"
  done | grep "is a member" | cut -d " " -f 1
}

function fixperms {
  find "$1" -type f -print -exec chmod 644 {} \;
  find "$1" -type d -print -exec chmod 755 {} \;
}

