# Print the contents of a property list in XML format.
function plcat --argument-names file
    if test -z "$file"
        echo "Usage: plcat file"
        return 1
    else if not test -e $file
        echo "$file does not exist"
        return 2
    end

    plutil -convert xml1 -o - -- $file
end
