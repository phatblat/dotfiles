function moj_host \
    --description='Prints an emoji for the current host.'

    set -l host (hostname)
    if string match '*.*'
        set domain (string split '.' #host)[2]
        echo domain $domain
    end

    switch $host
        case greymatter hi-c-era.local
            echo 💻
        case imac rundmg
            echo 🖥
        case mini
            echo ⌨️
        case '*'
            echo (string sub --length 1 (hostname))❓
    end
end
