# Installs and updates npm modules.
# https://docs.npmjs.com/cli
#
# Sequencing
# - After: brew (installed with node)
function 🕸__npm
    echo "🕸  NPM"
    echo

    # Ensure NPM is installed.
    if not which -s npm
        error "NPM is not installed."
        return 1
    end

    # Verify the user owns the node_modules dir.
    set -l global_modules /usr/local/lib/node_modules
    if test $USER != (fileowner $global_modules)
        if status is-login
            echo "You must be the owner of "$global_modules" to run this command."
        end
        return 1
    end

    set -l global_packages \
        eslint \
        express-generator \
        fast-cli \
        gitmoji-cli \
        jshint \
        markdownlint \
        n \
        ralio \
        realm-cli \
        realm-object-server \
        ts2kt

    set -l installed_packages (npm list -g --depth=0)
    # Example output:
    # /usr/local/lib
    # ├── fast-cli@0.2.1
    # ├── n@2.1.7
    # ├── npm@4.5.0
    # └── ralio@0.6.1
    # Manual installation check
    # string match "*ralio*" $installed_packages[5]

    echo "Updating NPM"
    npm install npm@latest -g

    # TODO: Add package uninstall

    # Update
    npm update -g

    # TODO: Refactor to only install missing packages
    npm install --global $global_packages

    npm doctor
end
