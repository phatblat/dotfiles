# 
function pushmobilespec
      # Optional first arg is spec file name
  if [[ -n $1 ]]; then
    spec_file="$1"
  else
    # Attempt to locate spec in current dir when not file name provided
    specs=($(ls -1 *.podspec | paste -sd " " -))
    spec_count=${#specs[@]}

    # If specs does not contain an array, spec_count will be a char count
    # if [[ ! $(declare -p specs 2> /dev/null | grep -q '^typeset \-a') ]]; then
    if (( spec_count == 1 )); then
      spec_file="${specs}"
    elif (( spec_count == 0 )); then
      echo "No podspecs found in the current directory."
      return 1
    else
      echo "Multiple podspecs found in the current directory (${spec_count}). Please specify which spec you would like to publish.\n  pushmobilespec Pod.podspec"
      return 2
    fi
  fi

  spec_repo_name="KPMobileSpecs"

  bundle exec pod repo push \
    "${spec_repo_name}" \
    "${spec_file}" \
    --sources=git@github.kp.org:internal-pods/specs,git@github.kp.org:mirrored-pods/specs,git@github.kp.org:F978034/KPMobileSpecs \
    --use-libraries \
    --private \
    --allow-warnings $argv
end
