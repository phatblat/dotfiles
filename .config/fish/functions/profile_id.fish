#!/usr/bin/env fish
# Extracts the UUID from a .mobileprovision profile.
function profile_id --argument-names profile
    if test -z $profile
        echo "Usage: profile_id AppProfile.mobileprovision"
        return 1
    end

    egrep -a -A 2 UUID $profile \
        | grep string \
        | sed -e 's/<string>//' -e 's/<\/string>//' -e 's/[ 	]//'
end
