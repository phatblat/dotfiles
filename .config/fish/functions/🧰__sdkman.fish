# Installs and updates SDKs.
# https://sdkman.io/
# curl -s "https://get.sdkman.io/" | bash
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

    if not test -d $sdkman_prefix
        curl -s "https://get.sdkman.io/" | bash
    end

    sdk selfupdate
    sdk current

end
