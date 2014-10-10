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
	build_version=$(agvtool what-version -terse)
	market_version=$(agvtool what-marketing-version -terse1)

	case "$1" in
	    build)
			echo "$build_version"
	        ;;
	    market)
			echo "$market_version"
	        ;;
	    *)
			# No args, output pretty format
			echo "$market_version ($build_version)"
	        ;;
	esac
}
