function serve \
        --wraps jekyll \
        --description='Runs Jekyll server in the foreground with the given environment variables.'

    set reflog_content ~/dev/www/reflog/www
    if test "$pwd" != "$reflog_content"
        pushd $reflog_content
    end

    open http://0.0.0.0:4000/
    env (cat .env | xargs) ../bin/jekyll serve $argv
end
