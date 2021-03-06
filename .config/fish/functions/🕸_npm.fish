# https://docs.npmjs.com/cli
#
# Sequencing
# - After: brew (installed with node)
function 🕸_npm \
    --description='Installs and updates npm modules.'

    echo "🕸 NPM"
    echo

    # Ensure NPM is installed.
    if not type -q npm
        error "NPM is not installed."
        return 1
    end

    # Verify the user owns the node_modules dir.
    set -l global_modules /usr/local/lib/node_modules
    mkdir /usr/local/lib/node_modules
    popd
    if test $USER != (fileowner $global_modules)
        if status is-login
            echo "You must be the owner of "$global_modules" to run this command."
        end
        return 1
    end

    set -l global_packages \
        atlas-connect \
        eslint \
        express-generator \
        fast-cli \
        gitmoji-cli \
        gulp \
        jshint \
        json5 \
        lynn-cli \
        markdownlint \
        mongodb-realm-cli \
        n \
        node-pre-gyp \
        npm-check-updates \
        pocket-cli \
        ralio \
        realm-cli \
        ts2kt \
        tslint \
        ubolt

    set -l installed_packages (npm list --global --depth=0)
    # Example output:
    # /usr/local/lib
    # ├── fast-cli@0.2.1
    # ├── n@2.1.7
    # ├── npm@4.5.0
    # └── ralio@0.6.1
    # Manual installation check
    # string match "*ralio*" $installed_packages[5]

    echo "Updating NPM"
    npm install npm@latest --global

    # Uninstall
    npm uninstall --global \
        ngrok \
        realm-object-server

    # Update
    npm update --global

    # TODO: Refactor to only install missing packages
    npm install --global $global_packages

    npm doctor
end
