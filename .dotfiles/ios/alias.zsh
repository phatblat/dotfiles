#-------------------------------------------------------------------------------
#
# ios/alias.zsh
# Command-line aliases for iOS development
#
#-------------------------------------------------------------------------------
# Xcode
alias ox='open *.xcodeproj'
alias ow='open *.xcworkspace'

# agvtool
function version() {
	# agvtool_path="/usr/bin/agvtool"
	agvtool_path=$(which agvtool)
	build_version=$(agvtool what-version -terse)
	market_version=$(agvtool what-marketing-version -terse1)
	echo "$market_version ($build_version)"
}

#-------------------------------------------------------------------------------
#
# Examples
#
#-------------------------------------------------------------------------------

# function sshnewkey() {
# 	if (($+1)); then
# 		ssh-keygen -t rsa -C "$1"
# 	else
# 		echo "Usage: sshnewkey user@host"
# 	fi
# }

# function fixperms() {
# 	find "$1" -type f -print -exec chmod 644 {} \;
# 	find "$1" -type d -print -exec chmod 755 {} \;
# }
