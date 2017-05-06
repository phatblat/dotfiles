
# null
function killsim
    launchctl list com.apple.CoreSimulator.CoreSimulatorService && ps aux | grep CoreSimulator && launchctl remove com.apple.CoreSimulator.CoreSimulatorService && echo "CoreSimulatorService has been removed from launchctl."
end
