# Prints size of files in bytes.
function filesize --argument-names file
    if test -z $file
        echo "Usage: filesize filename"
        return 1
    end

    stat -f%z $file
end
