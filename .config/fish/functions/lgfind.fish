# Search through lightweight log `lg` for a specific pattern.
function lgfind --argument-names search_term
    if test -z "$search_term"
        echo "Usage: lgfind 'search term'"
        return 1
    end

    lg -S $search_term
end
