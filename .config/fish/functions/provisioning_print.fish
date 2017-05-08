# Prints a text version of a provisioning profile.
function provisioning_print
    security cms -D -i $argv
end
