#!/usr/bin/env fish
# Prints the choices available in the given installation package.
function install_choices --argument-names package_file
    if test -z $package_file
        echo "Usage: install_choices file.pkg"
        return 1
    else if not string match '*.pkg' $package_file >/dev/null
        echo "This command requires an installer package (.pkg) file."
        return 2
    else if not test -e $package_file
        echo "$package_file does not exist."
        return 3
    end

    installer -showChoicesXML \
        -package $package_file \
        -target /
end
