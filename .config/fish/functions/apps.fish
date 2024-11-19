function apps \
    --description='Lists macOS apps currently installed' \
    --argument-names option

    if test -z "$option"
        set option default
    end

    switch $option
        case default
            # Just the ones you probably care about
            find /Applications -iname '*.app' -maxdepth 1
        case all
            # All apps under /Applications
            find /Applications -iname '*.app'
        case mas appstore app-store
            # MAS apps
            find /Applications -path '*Contents/_MASReceipt/receipt' -maxdepth 4 -print | sed 's#.app/Contents/_MASReceipt/receipt#.app#g; s#/Applications/##'
        case '*'
            echo "Usage: apps [all|mas]"
            return 1
    end
end
