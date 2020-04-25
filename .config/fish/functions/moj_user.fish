function moj_user \
    --description='Prints an emoji for the current user.'

    switch $USER
        case admin
            echo 🙆🏻‍♂️
        case ben 'f*'
            echo 🚶
        case benchatelain chatelain
            echo 👨🏻‍🚀
        case phatblat
            echo 🎧
        case jenkins
            echo 👷🏻‍♂️
        case '*'
            echo (string sub --length 1 $USER)❓
    end
end
