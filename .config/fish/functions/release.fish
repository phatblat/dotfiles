# 
function release
      local dirty

  # Ensure current dir is in a clean git repo
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    dirty=$(git status --porcelain)
    if [[ -n $dirty ]]; then
      echo "Can't release with a dirty work tree"
      return 1
    fi

    # Verify that there is a valid Xcode project in the current dir
    version_build > /dev/null
    if [ $? -ne 0 ]; then
      agvtool what-version
      return 1
    fi

    # Release notes
    echo "Have you checked in your release notes?"
    select yn in "Yes" "No"; do
      case $yn in
        Yes ) echo "YES"; break;;
        No ) echo "NO"; return 0;;
      esac
    done

    # Version
    version bump
    build_version=$(version_build)

    # Track and share
    git add --update
    git commit --message "Version $build_version"
    git tag "release/$build_version"
    # TODO: Determine default remote to used so that push commands can be combined
    # branch=$(git symbolic-ref --short HEAD)
    git push
    git push --tags

    # Final status
    version

    # Crashlytics
    # crashlytics_submit=$(find . -name submit 2>/dev/null)
    # if $(crashlytics_submit); then
    #     echo "Upload build to Crashlytics?"
    #     select yn in "Yes" "No"; do
    #         case $yn in
    #             Yes ) echo "YES"; break;;
    #             No ) echo "NO"; return 0;;
    #         esac
    #     done
    #     $crashlytics_submit ...
    # fi
  else
      echo "The release command must be run in a git repo"
  fi $argv
end
