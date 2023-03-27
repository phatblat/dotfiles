#!/usr/bin/env bash
#
# .bash_profile
#

# linux PATHs
# export PATH=/snap/bin:${PATH}
# export PATH=/home/linuxbrew/.linuxbrew/sbin:${PATH}
# export PATH=/home/linuxbrew/.linuxbrew/bin:${PATH}

export PATH="/opt/homebrew/bin:$PATH"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="${HOME}/.sdkman"
[[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh"

. "${HOME}/.cargo/env"

source /Users/phatblat/.config/broot/launcher/bash/br
