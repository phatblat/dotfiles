function clone \
        --description="Performs a git clone, then configures repo user." \
        --argument-names url dir

    if test -z "$url"
        echo "Usage: clone url [dir]"
        return 1
    end
    if test -z "$dir"
        set dir (string split '.' (string split '/' $url)[2])[1]
    end

    git clone -- $url $dir
    and pushd $dir
    and user.email (email_url $url)
    and user
end
