#-------------------------------------------------------------------------------
#
# xcode/getudid.zsh
# Prints out the UDID of all connected devices.
# http://www.neglectedpotential.com/2015/03/simple-script-for-getting-a-devices-udid/
#
#-------------------------------------------------------------------------------

lj info 'xcode/getudid.zsh'

function getudid {
  udid=($(system_profiler SPUSBDataType | grep -A 11 -w "iPad\|iPhone\|iPad" | grep "Serial Number" | awk '{ print $3 }'))
  if [ -z $udid ]; then
    echo "No device detected. Please ensure an iOS device is plugged in."
    exit 1
  else
    for i in "${udid[@]}"; do
      echo -n $i | pbcopy
      echo "UDID: $i"
    done
  fi
}
