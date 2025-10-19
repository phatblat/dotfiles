#!/usr/bin/env fish
# Displays CoreSimulatorService info before removing it from launchctl.
function killsim
    launchctl list com.apple.CoreSimulator.CoreSimulatorService
    ps aux | grep CoreSimulator
    
    launchctl remove com.apple.CoreSimulator.CoreSimulatorService; and \
        echo "CoreSimulatorService has been removed from launchctl."
end
