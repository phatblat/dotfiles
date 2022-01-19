# Sequencing
# - Requires mint.
function 🌱_mint \
    --description='Updates Mint and installed packages.'

    echo "🌱 Mint - https://github.com/yonaskolb/Mint"
    echo

    # List of packages to upstall
    set -l packages \
        jkmathew/Assetizer \
        artemnovichkov/Carting \
        num42/icon-resizer-swift \
        mono0926/LicensePlist \
        yonaskolb/SwagGen \
        thii/xcbeautify \
        yonaskolb/XcodeGen \
        ChargePoint/xcparse

    set -l uninstall

    # --------------------------------------------------------------------------
    #
    # Preflight Checks
    #
    # --------------------------------------------------------------------------

    # Ensure Mint is installed.
    if not type -q mint
        error "Mint is not installed"
        return 1
    end

    mint list

    # --------------------------------------------------------------------------
    #
    # Uninstall
    #
    # --------------------------------------------------------------------------

    # Uninstall unwanted packages
    set -l to_uninstall
    for package in $uninstall
        echo 🗑️ Uninstalling $to_uninstall
        mint uninstall $to_uninstall
    end

    # --------------------------------------------------------------------------
    #
    # Upstall
    #
    # --------------------------------------------------------------------------

    # Mint has no update command, so force install all packages
    for package in $packages
        echo 🆕 Installing: $package
        mint install --force --verbose $package
    end
end
