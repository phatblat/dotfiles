function update_nvm \
    --description 'Upstalls NVM' \
    --argument-names nvm_version

    if test -z $nvm_version
        set nvm_version 0.40.1
    end

    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v$nvm_version/install.sh | bash
end
