function serve \
        --description='Runs Jekyll server in the foreground with the given environment variables.'
    set reflog_content ~/dev/www/reflog/www
    pushd $reflog_content

    env (cat .env | xargs) ../bin/jekyll serve $argv
    popd
end
