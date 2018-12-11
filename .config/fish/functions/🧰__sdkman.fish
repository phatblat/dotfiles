# Installs and updates SDKs.
# https://sdkman.io/
# https://get.sdkman.io/
# https://github.com/sdkman/sdkman-cli
#
# Sequencing
# - After: omf
function 🧰__sdkman
    echo "🧰 SDKman"
    echo

    if test -z "$sdkman_prefix"
        error "\$sdkman_prefix is not set"
        return 1
    end

    # Using /bin dir as test because /etc is tracked in dotfiles
    if not test -d $sdkman_prefix/bin
        curl -s "https://get.sdkman.io/" | bash
    end

    sdk selfupdate
    sdk current
    sdk update
end
