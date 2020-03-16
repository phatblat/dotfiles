function version_market \
    --description='Displays the marketing version of the current Xcode project.'

    # Legacy agvtool command
    # agvtool what-marketing-version -terse1 $argv


    # Smarter logic which resolves build settings from project
    set -l plistbuddy /usr/libexec/PlistBuddy
    set -l plist_key "CFBundleShortVersionString"
    set -l build_setting_name "MARKETING_VERSION"

    echo $plist_key
    set -l plist_files (ls -1 **/*Info.plist)
    for file in $plist_files
        $plistbuddy -c "Print :$plist_key" $file
    end

    set -l project_file (ls -1 *xcodeproj/project.pbxproj)
    echo $project_file # L8r.xcodeproj/project.pbxproj

    # rootObject = F86CA260241E74FB004C3909 /* Project object */;
    set -l root_object ($plistbuddy -c "Print :rootObject" $project_file)
    echo "root_object: $root_object"

    # buildConfigurationList from Project object
    set -l build_config_list ($plistbuddy -c "Print :objects:$root_object:buildConfigurationList" $project_file)
    echo "build_config_list: $build_config_list"

    # buildConfigurations
    set -l build_configs
    for index in (seq 0 10) # assuming no more than 10 build configs
        set build_configs ($plistbuddy -c "Print :objects:$build_config_list:buildConfigurations:$index" $project_file 2>/dev/null) $build_configs
        if not test $status -eq 0
            break
        end
    end
    echo "build_configs: $build_configs"

    # buildSettings
    echo $build_setting_name
    set -l marketing_versions
    for config in $build_configs
        echo $config
        set marketing_versions ($plistbuddy -c "Print :objects:$config:buildSettings:$build_setting_name" $project_file) $marketing_versions
    end

    echo $marketing_versions
end
