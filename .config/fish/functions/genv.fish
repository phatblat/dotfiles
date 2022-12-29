function genv \
    --description='Grep environment' \
    --argument-names search_term

    if test -z $search_term
        echo 'Usage: genv search_term'
        return 1
    end

    env | grep -i $search_term
end
