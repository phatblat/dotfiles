#!/usr/bin/env fish
function xamarin_version \
    --description='Determines the current version Xamarin'

    set --local xamarin_ios /Library//Frameworks/Xamarin.iOS.framework/Versions

    echo -n "Xamarin.iOS: "
    command ls -1 $xamarin_ios | head -1
end
