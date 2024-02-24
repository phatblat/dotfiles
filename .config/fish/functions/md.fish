function md --argument-names path --description 'Make dir and pushd into it.'
    if test -z $path
        echo "Usage: md path"
        return 1
    end

    mkdir -p $path
    and pushd $path
end
