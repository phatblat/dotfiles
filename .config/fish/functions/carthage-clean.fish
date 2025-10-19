#!/usr/bin/env fish
# Clean the Carthage cache folder.
function carthage-clean
    rm -rf ~/Library/Caches/org.carthage.CarthageKit $argv
end
