function update_nvm \
    --description 'Upstalls NVM' \
    --argument-names nvm_version

    if test -z $nvm_version
        # Fetch the latest version from GitHub
        set nvm_version (curl --silent https://api.github.com/repos/nvm-sh/nvm/releases/latest | jq -r '.tag_name')
    end

    echo "Upstalling NVM version $nvm_version"

    curl --silent https://raw.githubusercontent.com/nvm-sh/nvm/$nvm_version/install.sh | bash
end
