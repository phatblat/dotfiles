# macos — local machine status and system-scoped installs

alias f := free

# Display free space on the Data volume (~ resolves to it; / is the sealed, near-empty System volume)
[group('macos')]
free:
    @avail=$(df -h ~ | awk 'NR==2 {print $4}'); df -Pk ~ | awk -v avail="$avail" 'NR==2 {printf "Free space: %s (%.0f%% available)\n", avail, 100 * $4 / ($3 + $4)}'

# Installs LaunchDaemons into /Library/LaunchDaemons (prompts for sudo)
[group('macos')]
install-launchdaemons:
    ./scripts/install-launchdaemons

# Installs LaunchAgents into ~/Library/LaunchAgents (user-scoped, no sudo)
[group('macos')]
install-launchagents:
    ./scripts/install-launchagents
