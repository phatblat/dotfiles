#-------------------------------------------------------------------------------
#
# xcode/alias.zsh
# Command-line aliases for Xcode
#
#-------------------------------------------------------------------------------

alias ox='open *.xcodeproj'
alias ow='open *.xcworkspace'
alias bpx='bi && pi && ow'
alias xcodes='ls -ld /Applications/Xcode*'
alias xv='xcodebuild -version'
alias xcsp='xcode-select --print-path'
alias xcss='sudo xcode-select --switch'
alias xccheck='~/.dotfiles/xcode/xccheck.sh'
alias version_enable='ruby ~/.dotfiles/xcode/enable-versioning.rb'
alias version_build='agvtool what-version -terse'
alias version_market='agvtool what-marketing-version -terse1'
alias register_device="~/.dotfiles/xcode/register_device.rb"
alias devices='instruments -s devices'
alias developer_mode='DevToolsSecurity -status && sudo DevToolsSecurity -enable'
alias adev='open https://developer.apple.com/news/'
alias killsim='launchctl list com.apple.CoreSimulator.CoreSimulatorService && ps aux | grep CoreSimulator && launchctl remove com.apple.CoreSimulator.CoreSimulatorService && echo "CoreSimulatorService has been removed from launchctl."'
