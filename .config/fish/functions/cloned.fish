# Wrapper around clone which 'pushd's inot the new directory
function cloned --argument-names url dir
    if test -z "$url"
        echo "Usage: cloned url [dir]"
        return 1
    end
    if test -z "$dir"
        set dir (string split '.' (string split '/' $url)[2])[1]
    end

    clone $url $dir
    and pushd $dir
end
