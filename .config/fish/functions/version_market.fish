function version_market \
    --description='Displays the marketing version of the current Xcode project.'

    agvtool what-marketing-version -terse1 $argv
end
