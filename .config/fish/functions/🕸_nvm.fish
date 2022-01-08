# https://github.com/nvm-sh/nvm
# https://github.com/jorgebucaran/nvm.fish
#
# Sequencing
# - After: fisher
function 🕸_nvm \
    --description='Installs nvm and updates node.'

    echo "🕸 NVM"
    echo

    # Ensure NVM is installed.
    if not type -q nvm
        error "NVM is not installed."
        return 1
    end

    nvm use node
end
