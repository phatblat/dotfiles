# version_build - Displays the project (aka build) version of the current Xcode project
export def version_build [] {
    let plistbuddy = "/usr/libexec/PlistBuddy"
    let build_setting_name = "CURRENT_PROJECT_VERSION"

    let project_file = (
        ^find . -maxdepth 2 -name "project.pbxproj" -path "*xcodeproj*"
        | lines
        | first
    )
    if ($project_file | is-empty) {
        print --stderr "No xcodeproj found in current directory"
        error make { msg: "No xcodeproj found" }
    }

    let root_object = (^$plistbuddy -c "Print :rootObject" $project_file | str trim)
    let build_config_list = (^$plistbuddy -c $"Print :objects:($root_object):buildConfigurationList" $project_file | str trim)

    mut project_versions = []
    for index in 0..10 {
        let config = (try {
            ^$plistbuddy -c $"Print :objects:($build_config_list):buildConfigurations:($index)" $project_file | str trim
        } catch { "" })
        if ($config | is-empty) { break }
        let ver = (try {
            ^$plistbuddy -c $"Print :objects:($config):buildSettings:($build_setting_name)" $project_file | str trim
        } catch { "" })
        if ($ver | is-not-empty) {
            $project_versions = ($project_versions | append $ver)
        }
    }

    $project_versions | uniq | first
}
