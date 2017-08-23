# Updates Atom packages.
# https://atom.io/packages
#
# Sequencing
# - After: cask (atom)
function ⚛️__apm
    echo "⚛️  Atom Package Manager"
    echo

    set -l packages \
        build \
        build-gradle \
        build-npm-apm \
        busy \
        dash \
        language-fish-shell \
        language-gradle \
        linter \
        merge-conflicts \
        minimap \
        octocat-syntax \
        pigments \
        ruby-bundler \
        script \
        spell-check-project \
        spell-check-test \
        vim-mode

    set -l uninstall

    set -l installed
    set -l installed_with_version (apm list --installed --bare)
    for package in $installed_with_version
        # Strip off version numbers
        set -l bare_package (string replace --regex "@.*" "" -- $package)
        set installed $installed $bare_package
    end

    # --------------------------------------------------------------------------
    #
    # Uninstall
    #
    # --------------------------------------------------------------------------

    # Uninstall unwanted packages
    set -l to_uninstall
    for package in $uninstall
        if contains $package $installed
            set to_uninstall $to_uninstall $package
        end
    end
    if test -n "$to_uninstall"
        apm uninstall $to_uninstall
    end

    # --------------------------------------------------------------------------
    #
    # Upstall
    #
    # --------------------------------------------------------------------------

    # Update installed packages
    apm outdated --list; or apm update

    # Install new formula
    set -l not_installed
    for package in $packages
        if not contains $package $installed
            # Include package flags when installing
            set not_installed $not_installed $package
        end
    end
    if test -n "$not_installed"
        for package in $not_installed
            echo "Installing $package"
            apm install $package
        end
    end
end
