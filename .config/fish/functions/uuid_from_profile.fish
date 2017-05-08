# 
function uuid_from_profile
      print_profile $1 | grep UUID -A 1 | tail -n 1 | cut -d ">" -f 2 | cut -d "<" -f 1 $argv
end
