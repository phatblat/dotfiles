#-------------------------------------------------------------------------------
#
# cron/testing.sh
# Tesing out shell commands.
#
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# Current host machine
this_host=$(hostname)
echo "this_host: $this_host \c"

if [[ $this_host != "imac.local" ]]; then
  echo "(not iMac)"
  exit
fi

echo "(iMac)"


#-------------------------------------------------------------------------------
# Arrays

shells=(bash zsh fish)
echo "All shells: ${shells[*]}"


#-------------------------------------------------------------------------------
# Menu Selection

shopt -s extglob

select yn in "Yes" "Yeah" "yes" "No"; do
  case $yn in
    @(Y*|y*) ) echo "YES"
      break;;
    No ) echo "NO"
      break;;
  esac
done
