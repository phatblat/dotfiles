#!/usr/bin/env fish
# Connect to Jenkins Dev using SSH.
function jenkins_restart
    set -l jenkins_service_config /Library/LaunchDaemons/jenkins.plist
    if not test -e $jenkins_service_config
        error $jenkins_service_config is not present on this Mac.
        return 1
    end

    sudo launchctl unload $jenkins_service_config
    sudo launchctl load $jenkins_service_config
    sudo launchctl list | grep jenkins
end
