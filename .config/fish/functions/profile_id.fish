# 
function profile_id
      if [[ $# -ne 1 ]]; then
    echo "Usage: profile_id AppProfile.mobileprovision"
    return 1
  fi

  egrep -a -A 2 UUID $1 | grep string | sed -e 's/<string>//' -e 's/<\/string>//' -e 's/[ 	]//' $argv
end
