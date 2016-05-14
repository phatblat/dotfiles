#-------------------------------------------------------------------------------
#
# cron/testing.sh
# Tesing out shell commands.
#
#-------------------------------------------------------------------------------

this_host=$(hostname)
echo "this_host: $this_host \c"

if [[ $this_host != "imac.local" ]]; then
  echo "(not iMac)"
  exit
fi

echo "(iMac)"
