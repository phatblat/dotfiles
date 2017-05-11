# Displays the project (aka build) version of the current Xcode project
function version_build
    agvtool what-version -terse $argv
end
