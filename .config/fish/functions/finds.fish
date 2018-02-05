# Finds files under the given base_dir (defaults to PWD)
# which contain search_term glob. Note that search_term needs to match
# the entire filename.
function finds --argument-names search_term base_dir
    if test -z $search_term
        echo "Missing search term"
        echo 'Usage: finds "search string" /base/dir'
        return 1
    end

    if test -z $base_dir
        set base_dir .
    end

    if not test -e $base_dir
        echo "'$base_dir' does not exist"
        return 2
    end

    echo "search_term: $search_term"
    echo "base_dir: $base_dir"
    echo "-----------------------------------"

    find "$base_dir" -name "*$search_term*" -print
end
