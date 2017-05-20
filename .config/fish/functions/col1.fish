# Prints the first column of input (first argument)
function col1 --argument-names arg1
    if test -z $arg1
        echo "Usage: col1 arg1 ..."
        return 1
    end

    # cut is used since list values can contain spaces
    # or: awk '{print $1}' (instead of cut)
    echo $arg1 | cut -f 1 -d ' ' -
end
