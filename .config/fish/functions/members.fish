# 
function members
      dscl . -list /Users | while read user
  do printf "$user "
    dsmemberutil checkmembership -U "$user" -G "$*"
  done | grep "is a member" | cut -d " " -f 1 $argv
end
