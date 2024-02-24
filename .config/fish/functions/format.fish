function format \
    --description='Format files' \
    --argument-names type

    if test -z $type
        echo 'Usage: format [type]'
        return 1
    end


    switch $type
        case fish
            # Format fish files
            fish_format ~/.config/fish/functions/*.fish
        case '*'
            echo "Unsupported file type: $type"
            return 1
    end
end
