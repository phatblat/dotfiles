#-------------------------------------------------------------------------------
#
# xcode/alias.zsh
# Command-line aliases for Xcode
#
#-------------------------------------------------------------------------------

# Quick Open Commands
alias ox='open *.xcodeproj'
alias ow='open *.xcworkspace'
alias bpx='bi && pi && ow'

# Xcode versions
alias adev='open https://developer.apple.com/news/'
alias xcodes='ls -ld /Applications/Xcode*'
alias xv='xcodebuild -version'
alias xcsp='xcode-select --print-path'
alias xcss='sudo xcode-select --switch'
alias xccheck='~/.dotfiles/xcode/xccheck.sh'

function xclinkapp {
  if [[ $# -ne 1 ]]; then
    echo "Usage: xclinkapp <Version>"
    echo "Version format: 8.3.2"
    return 1
  fi
  local VERSION="$1"
  echo "Activating Xcode Version: ${VERSION}"
  # return 0

  rm -f "/Applications/Xcode.app"
  ln -s "/Applications/Xcode-${VERSION}.app" "/Applications/Xcode.app"
  xcodes
  xcss "/Applications/Xcode-${VERSION}.app"
  xcsp
}

# Project Versioning
alias version_enable='ruby ~/.dotfiles/xcode/enable-versioning.rb'
alias version_build='agvtool what-version -terse'
alias version_market='agvtool what-marketing-version -terse1'

# Devices
alias devices='instruments -s devices'
alias register_device="~/.dotfiles/xcode/register_device.rb"
alias developer_mode='DevToolsSecurity -status && sudo DevToolsSecurity -enable'
alias killsim='launchctl list com.apple.CoreSimulator.CoreSimulatorService && ps aux | grep CoreSimulator && launchctl remove com.apple.CoreSimulator.CoreSimulatorService && echo "CoreSimulatorService has been removed from launchctl."'
