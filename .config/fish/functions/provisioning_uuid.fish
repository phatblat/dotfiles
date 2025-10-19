#!/usr/bin/env fish
# Prints the UUID 
function provisioning_uuid --argument-names profile_path
    if test -z $profile_path
        echo "Usage: profile_uuid path/to/profile.mobileprovision"
        return 1
    end

    provisioning_print $profile_path \
        | grep UUID -A 1 \
        | tail -n 1 \
        | cut -d ">" -f 2 \
        | cut -d "<" -f 1
end
