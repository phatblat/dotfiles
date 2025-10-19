#!/usr/bin/env fish
# Shows metadata for the given installer package.
function pkginfo --argument-names package_identifier
    if test -z $package_identifier
        echo "Usage: pkginfo package_identifier"
        return 1
    end

    pkgutil --pkg-info $package_identifier
end
