# https://sdkman.io/
# https://get.sdkman.io/
# https://github.com/sdkman/sdkman-cli
#
# Sequencing
# - After: omf
function 🧰_sdkman \
    --description='Installs and updates SDKs'

    echo "🧰 SDKman"
    echo

    if test -z "$sdkman_prefix"
        error "\$sdkman_prefix is not set"
        return 1
    end

    # Using /bin dir as test because /etc is tracked in dotfiles
    if not test -d "$sdkman_prefix/bin"
        echo "Installing SDKman"
        # Remove tracked etc/config file so that sdkman will actually install
        rm -rf $sdkman_prefix/
        curl -s "https://get.sdkman.io/" | bash
        git checkout $sdkman_prefix
    end

    sdk env install
    sdk selfupdate
    sdk current
    sdk update
end
