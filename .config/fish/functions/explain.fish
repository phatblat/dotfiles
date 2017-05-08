# 
function explain
      alias | grep $1

  # 'type' prints out what the given argument is, if found.
  # helpful for finding functions, which aren't included in the alias output
  output=$(type $1)
  if [[ $? -eq 0 ]]; then
    # Echo output on success
    echo ${output}
  fi $argv
end
