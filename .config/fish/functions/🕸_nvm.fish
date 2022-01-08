# https://github.com/nvm-sh/nvm
# https://github.com/jorgebucaran/nvm.fish
#
# Sequencing
# - After: fisher
function 🕸_nvm \
    --description='Installs nvm and updates node.'

    echo "🕸 NVM - https://nvm.sh"
    echo

    # Ensure NVM is installed.
    if not type -q nvm
        error "NVM is not installed."
        return 1
    end

    # Upgrade node & npm
    nvm install node --latest-npm
    nvm current > ~/.nvmrc
end
