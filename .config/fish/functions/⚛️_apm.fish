# https://atom.io/packages
#
# Sequencing
# - After: cask (atom)
function ⚛️_apm \
    --description 'Updates Atom packages.'

    echo "⚛️  Atom Package Manager"
    echo

    set -l packages \
        atom-ide-ui \
        bottom-dock \
        build \
        build-npm-apm \
        busy \
        dash \
        gradle-manager \
        ide-html \
        ide-java \
        ide-json \
        ide-typescript \
        ide-yaml \
        language-fish-shell \
        language-gradle \
        language-groovy \
        linter \
        merge-conflicts \
        minimap \
        octocat-syntax \
        pigments \
        ruby-bundler \
        script \
        spell-check-project \
        spell-check-test \
        vim-mode-plus

    set -l uninstall \
        build-gradle \
        vim-mode

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
    test (apm upgrade --list --json | jq length) -eq 0; or apm upgrade --no-confirm

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
