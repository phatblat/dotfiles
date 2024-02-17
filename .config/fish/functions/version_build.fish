function version_build \
    --description='Displays the project (aka build) version of the current Xcode project.'

    # Legacy agvtool command
    # agvtool what-version -terse $argv

    # Smarter logic which resolves build settings from project
    set -l plistbuddy /usr/libexec/PlistBuddy
    set -l plist_key CFBundleVersion
    set -l build_setting_name CURRENT_PROJECT_VERSION

    debug $plist_key
    set -l plist_files (ls -1 **/*Info.plist)
    for file in $plist_files
        debug $plistbuddy -c "Print :$plist_key" $file
    end

    set -l project_file (ls -1 *xcodeproj/project.pbxproj)
    debug $project_file # L8r.xcodeproj/project.pbxproj

    # rootObject = F86CA260241E74FB004C3909 /* Project object */;
    set -l root_object ($plistbuddy -c "Print :rootObject" $project_file)
    debug "root_object: $root_object"

    # buildConfigurationList from Project object
    set -l build_config_list ($plistbuddy -c "Print :objects:$root_object:buildConfigurationList" $project_file)
    debug "build_config_list: $build_config_list"

    # buildConfigurations
    set -l build_configs
    for index in (seq 0 10) # assuming no more than 10 build configs
        set build_configs ($plistbuddy -c "Print :objects:$build_config_list:buildConfigurations:$index" $project_file 2>/dev/null) $build_configs
        if not test $status -eq 0
            break
        end
    end
    debug "build_configs: $build_configs"

    # buildSettings
    debug $build_setting_name
    set -l project_versions
    for config in $build_configs
        set project_versions ($plistbuddy -c "Print :objects:$config:buildSettings:$build_setting_name" $project_file) $project_versions
    end

    echo $project_versions
end
