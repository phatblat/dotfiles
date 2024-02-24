function ditto_debug \
    --description 'Toggles the DITTO_DEBUG flag.' \
    --argument-names state

    if test -z $state
        echo 'Usage: ditto_debug [on/off]'
        return 1
    end


    switch $state
        case on ON On
            set --global --export DITTO_DEBUG 1
            echo " (DITTO_DEBUG=1)"
        case off OFF Off
            set --erase DITTO_DEBUG
            echo " (DITTO_DEBUG removed)"
        case '*'
            echo "Usage: ditto_debug [on|off]"
            return 1
    end
end
