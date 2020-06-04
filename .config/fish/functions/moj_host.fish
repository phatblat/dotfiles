function moj_host --description='Prints an emoji for the current host.'
    set -l host (hostname)
    if string match '*.*' $host >/dev/null
        set -l tokens (string split '.' $host)
        set host $tokens[1]
        set domain $tokens[2]
    end

    switch $host
        case 'tredecim*' 'greymatter*' 'Bens-MacBook-Pro*' 'bens-mbp-wifi*' 'mcoe-am*'
            echo 💻
        case hacklet penguin pop-os 'labtop*'
            echo 🐧
        case imac octodec 'rundmg*'
            echo 🖥
        case mini
            echo ⌨️
        case '*'
            echo (string sub --length 1 (hostname))❓
    end
end
