function xcbschemes \
    --description='Displays schemes for an Xcode project'

    # Parse the xcodebuild -list output for schemes
    set --local schemes (xcblist \
        | grep Schemes: -A 10 \
        | tail -n +2 \
        | sed -e 's/^[ \t]*//')

    # Drop the last (empty) line
    set schemes $schemes[1..-2]

    for scheme in $schemes
        echo $scheme
    end
end
