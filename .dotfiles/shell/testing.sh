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
# Menu Selection

select yn in "Yes" "No"; do
  case $yn in
    Yes ) echo "YES"
      break;;
    No ) echo "NO"
      break;;
  esac
done
