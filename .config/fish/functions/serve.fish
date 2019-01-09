function serve \
        --wraps=jekyll \
        --description='Runs Jekyll server in the foreground with the given environment variables.'

    set reflog_content ~/dev/www/reflog
    if test "$PWD" != "$reflog_content"
        pushd $reflog_content
    end

    env (cat .env | xargs) jekyll serve --open-url $argv
end
