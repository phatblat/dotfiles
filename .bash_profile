#
# .bash_profile
#

# PATH
export PATH=/snap/bin:$PATH
export PATH=/home/linuxbrew/.linuxbrew/sbin:$PATH
export PATH=/home/linuxbrew/.linuxbrew/bin:$PATH

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="~/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"


# Ping Identity DevOps Aliases - Added with 'ping-devops config' on Mon Mar  1 14:49:30 MST 2021
test -f '/usr/local/etc/bash_profile.ping-devops' && source '/usr/local/etc/bash_profile.ping-devops'

# Source PingIdentity Files Alias - Added with 'ping-devops config' on Mon Mar  1 14:49:34 MST 2021
sourcePingIdentityFiles
. "$HOME/.cargo/env"
