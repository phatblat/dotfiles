function moj_host \
    --description='Prints an emoji for the current host.'
    set -l host (hostname)
    if string match '*.*' $host >/dev/null
        set -l tokens (string split '.' $host)
        set host $tokens[1]
        set domain $tokens[2]
    end

    switch $host
        case 'DTO-A017'
            echo 💻
        case phatmini co-mac1
            echo 🖥
        case m1 mini
            echo ⌨️
        case hacklet penguin pocket3 pop-os 'labtop*'
            echo 🐧
        case '*'
            echo (string sub --length 1 (hostname))❓
    end
end
