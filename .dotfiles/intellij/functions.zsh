#-------------------------------------------------------------------------------
#
# intellij/functions.zsh
# Command-line functions for IntelliJ
#
#-------------------------------------------------------------------------------

lj info 'intellij/functions.zsh'

# Launch IntelliJ IDEA
# https://gist.github.com/chrisdarroch/7018927
function idea {
  local dir

  # check for where the latest version of IDEA is installed
  IDEA=`ls -1d /Applications/IntelliJ\ * | tail -n1`

  # were we given a directory?
  if [ -d "$1" ]; then
    # echo "checking for things in the working dir given"
    dir=`ls -1d "$1" | head -n1`
  fi

  # were we given a file?
  if [ -f "$1" ]; then
  # echo "opening '$1'"
    open -a "$IDEA" "$1"
  else
      if [ -n "${dir}" ]; then
        # let's check for stuff in our working directory.
        pushd "${dir}" > /dev/null
      fi

      # does our working dir have an .idea directory?
      if [ -d ".idea" ]; then
        # echo "opening via the .idea dir"
        open -a "$IDEA" .

      # is there an IDEA project file?
      elif [ -f *.ipr ]; then
        # echo "opening via the project file"
        open -a "$IDEA" `ls -1d *.ipr | head -n1`

      # Is there a pom.xml?
      elif [ -f pom.xml ]; then
        # echo "importing from pom"
        open -a "$IDEA" "pom.xml"

      # can't do anything smart; just open IDEA
      else
        # echo 'cbf'
        open "$IDEA"
      fi

      if [ -n "${dir}" ]; then
        popd > /dev/null
      fi
  fi
}
