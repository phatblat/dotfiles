function moj_host --description='Prints an emoji for the current host.'
    set -l host (hostname)
    if string match '*.*' $host >/dev/null
        set -l tokens (string split '.' $host)
        set host $tokens[1]
        set domain $tokens[2]
    end

    switch $host
        case 'greymatter*'
            echo 💻
        case 'hi-c-era*'
            echo 🌋
        case imac 'rundmg*'
            echo 🖥
        case mini
            echo ⌨️
        case '*'
            echo (string sub --length 1 (hostname))❓
    end
end
