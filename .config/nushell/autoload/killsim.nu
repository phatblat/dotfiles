# Dependencies:
#   functions: none
#   builtins:  try
#   externals: launchctl ps grep

# Show CoreSimulatorService info then remove it from launchctl (diagnostics are best-effort)
export def killsim [] {
    try { ^launchctl list com.apple.CoreSimulator.CoreSimulatorService }
    try { ^ps aux | ^grep CoreSimulator }
    ^launchctl remove com.apple.CoreSimulator.CoreSimulatorService
    print "CoreSimulatorService has been removed from launchctl."
}
