#-------------------------------------------------------------------------------
#
# macos/system.zsh
#
#-------------------------------------------------------------------------------

function sysinfo {
  uname -a
  sw_vers -productVersion
  system_profiler SPSoftwareDataType
}

