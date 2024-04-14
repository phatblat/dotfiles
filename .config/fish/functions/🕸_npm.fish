# https://docs.npmjs.com/cli
#
# Sequencing
# - After: brew (installed with node)
function 🕸_npm \
    --description 'Installs and updates npm packages.'

    echo "🕸 NPM - https://www.npmjs.com/"
    echo

    # --------------------------------------------------------------------------
    #
    # Configuration
    #
    # --------------------------------------------------------------------------

    set -l global_packages \
        @bchatard/alfred-jetbrains \
        atlas-connect \
        dukat \
        eslint \
        express-generator \
        fast-cli \
        firebase-tools \
        generator-code \
        gitmoji-cli \
        gulp \
        @hubspot/cli \
        jake \
        jshint \
        json5 \
        lynn-cli \
        markdownlint \
        mongodb-realm-cli \
        monofo \
        n \
        node-pre-gyp \
        npm-check-updates \
        pocket-cli \
        ubolt \
        vsce \
        yarn-audit-fix \
        yo

    set -l uninstall \
        ralio \
        realm-cli \
        realm-object-server \
        ngrok \
        ts2kt \
        tslint

    # --------------------------------------------------------------------------
    #
    # Preflight Checks
    #
    # --------------------------------------------------------------------------

    # Ensure NPM is installed.
    if not type --query npm
        error "NPM is not installed."
        return 1
    end

    # Verify the user owns the node_modules dir.
    set -l global_modules (npm get prefix)"/lib/node_modules"
    if test $USER != (fileowner $global_modules)
        if status is-login
            echo "You must be the owner of "$global_modules" to run this command."
        end
        return 1
    end

    # --------------------------------------------------------------------------
    #
    # self-update
    #
    # --------------------------------------------------------------------------

    echo "⬆️ Updating NPM"
    npm install npm@latest --global

    # --------------------------------------------------------------------------
    #
    # Uninstall
    #
    # --------------------------------------------------------------------------

    # Uninstall unwanted packages
    set -l to_uninstall
    for package in $uninstall
        if contains $package $installed_packages
            set to_uninstall $to_uninstall $package
        end
    end
    if test -n "$to_uninstall"
        echo 🗑️ Uninstalling $to_uninstall
        npm uninstall --global $to_uninstall
    end

    # --------------------------------------------------------------------------
    #
    # Upstall
    #
    # --------------------------------------------------------------------------

    set -l outdated_json (npm outdated --global --json)
    if test ! "$outdated_json" = "{}"
        set -l outdated_packages (\
            echo "$outdated_json" | \
            jq --raw-output 'keys | .[] | "\(.)"'\
        )

        echo
        echo "👵🏻 Outdated: $outdated_packages"

        # npm outdated --global

        # Update global packages using npm-check-updates
        # ncu --global

        for package in $outdated_packages
            npm update --global $package
        end
    end

    # List only top-level dependencies
    set -l installed_packages (\
        npm list --global --depth=0 --json | \
        jq --raw-output '.dependencies | keys | .[] | "\(.)"'\
    )

    echo
    echo "📦 Installed packages: $installed_packages"

    # Install new packages not already installed.
    set -l not_installed
    for package in $global_packages
        if not contains $package $installed_packages
            set not_installed $not_installed $package
        end
    end
    if test -n "$not_installed"
        for package in $not_installed
            echo
            echo 🆕 Installing: $package
            npm install --global $package
        end
    end

    # --------------------------------------------------------------------------
    #
    # Post Install
    #
    # --------------------------------------------------------------------------

    echo
    echo 🧹 Clean Cache
    npm cache clean --force

    echo
    echo 👩🏻‍⚕️ Doctor
    npm doctor
end
