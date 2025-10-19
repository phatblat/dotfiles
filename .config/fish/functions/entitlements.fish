#!/usr/bin/env fish
# Display entitlements in the codesign information of a bundle.
function entitlements
    codesign -d --entitlements :- $argv
end
