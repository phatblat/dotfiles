# Displays the marketing version of the current Xcode project.
function version_market
    agvtool what-marketing-version -terse1 $argv
end
