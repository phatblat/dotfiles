function moj_user \
    --description='Prints an emoji for the current user.'

    switch $USER
        case 'admin'
            echo 🙆🏻‍♂️
        case 'ben'
            echo 🚶
        case 'chatelain'
            echo 👨🏻‍💻
        case 'phatblat'
            echo 🎧
        case '*'
            echo (string sub --length 1 $USER)❓
    end
end
