#-------------------------------------------------------------------------------
#
# xcode/plugins.zsh
# Command-line aliases for Xcode
#
#-------------------------------------------------------------------------------

lj info 'xcode/plugins.zsh'

# Alcatraz - http://alcatraz.io
alias alcatraz_install='curl -fsSL https://raw.githubusercontent.com/supermarin/Alcatraz/deploy/Scripts/install.sh | sh'
alias alcatraz_uninstall='trash ~/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins/Alcatraz.xcplugin'
alias alcatraz_clean='rm -rf ~/Library/Application\ Support/Alcatraz'

# xcode_plugin_update_uuid
#
# Blindly adds the DVTPlugInCompatibilityUUID for every version of Xcode found
# in /Applications to all Xcode plugins.
#
function xcode_plugin_update_uuid() {
  local xcode plugin

  for xcode in /Applications/Xcode*.app; do
    uuid=$(defaults read "$xcode/Contents/Info" DVTPlugInCompatibilityUUID)

    echo "$xcode - $uuid"

    for plugin in ~/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins/*.xcplugin; do
      echo "Updating $plugin"
      defaults write "$plugin/Contents/Info" DVTPlugInCompatibilityUUIDs -array-add $uuid
    done

  done
}
