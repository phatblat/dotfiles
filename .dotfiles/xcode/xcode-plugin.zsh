#!/bin/bash
#
# xcode-plugin.zsh
#

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

alias xcode_plugin_update_uuid=xcode_plugin_update_uuid
