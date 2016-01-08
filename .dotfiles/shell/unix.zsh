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

