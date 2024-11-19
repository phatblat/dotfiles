function doc \
    --description='Quickly launch docker containers in the current dir.' \
    --argument-names image_name image_version

    if test -z "$image_version"
        set image_version "latest"
    end

    docker run --rm --privileged --interactive --tty \
        --volume "$PWD:/src" \
        --workdir "/src" \
        $image_name:$image_version
end
