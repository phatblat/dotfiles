function moj_user \
    --description='Prints an emoji for the current user.'

    switch $USER
        case 'phatblat'
            echo 🎧
        case 'ben'
            echo 👨🏻‍💻👨🏻‍
        case '*'
            echo (string sub --length 1 $USER)❓
    end
end
