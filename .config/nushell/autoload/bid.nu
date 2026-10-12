# bid - Get bundle ID for app name
export def bid [...args: string] {
    let input = ($args | str join " ")
    let shortname = ($input | ^sed -E 's/\.app$//' | ^sed 's/\///g' | str trim)
    let loc1 = $"/Applications/($shortname).localized/($shortname).app"
    let loc2 = $"/Applications/($shortname).app"
    let home_apps = ("~/Applications" | path expand)

    let location = if ($loc1 | path exists) {
        $loc1
    } else if ($loc2 | path exists) {
        $loc2
    } else {
        let results = (^mdfind -onlyin /Applications -onlyin /Applications/Setapp -onlyin /Applications/Utilities -onlyin $home_apps -onlyin /Developer/Applications $"kMDItemKind==Application && kMDItemDisplayName=='*($shortname)*'cdw" | lines)
        if ($results | is-empty) { "" } else { $results | first }
    }

    if ($location | is-empty) {
        print $"($input) not found, I quit"
        return
    }

    let bundleid = (^mdls -name kMDItemCFBundleIdentifier -r $location | str trim)
    if ($bundleid | is-empty) {
        print $"Error getting bundle ID for \"($input)\""
    } else {
        print $"($location): ($bundleid)"
    }
}
