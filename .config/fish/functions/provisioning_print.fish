# Prints a text version of a provisioning profile.
function provisioning_print --argument-names profile_path
    if test -z $profile_path
        echo "Usage: provisioning_print path/to/profile.mobileprovision"
        return 1
    end

    if not test -e $profile_path
        echo $profile_path does not exist
        return 2
    end

    security cms -D -i $profile_path 2>/dev/null
end
