#!/usr/bin/env fish
# Forces a refresh of the "Open With" list of applications in the Finder.
function fixopenwith
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
    echo "Launch services has been refreshed. Run `killall Finder` to update the \"Open With\" list."
end
