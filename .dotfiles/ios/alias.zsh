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
	agvtool_path=$(which agvtool) # "/usr/bin/agvtool"

	case "$1" in
	    "build" | "-b")
			agvtool what-version -terse
	        ;;
	    "market" | "-m")
			agvtool what-marketing-version -terse1
	        ;;
	    *)
			# No args, output pretty format
			build_version=$(agvtool what-version -terse)
			market_version=$(agvtool what-marketing-version -terse1)
			echo "$market_version ($build_version)"
	        ;;
	esac
}
