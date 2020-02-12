function plcat \
    --description='Library/Preferences/com.mizage.Divvy.plist' \
    --argument-names file

    if test -z "$file"
        echo "Usage: plcat file"
        return 1
    else if not test -e $file
        echo "$file does not exist"
        return 2
    end

    plutil -convert xml1 -o - -- $file \
        | bat
end

