#!/usr/bin/env fish
# Shows files associated with the given installer package.
function pkgfiles --argument-names package_identifier
    if test -z $package_identifier
        echo "Usage: pkgfiles package_identifier"
        return 1
    end

    pkgutil --files $package_identifier
end
