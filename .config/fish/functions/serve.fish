#!/usr/bin/env fish
function serve \
        --wraps=jekyll \
        --description='Runs Jekyll server in the foreground with the given environment variables.'

    set reflog_content ~/dev/www/reflog
    if test "$PWD" != "$reflog_content"
        pushd $reflog_content
    end

    env (cat .env | xargs) bundle exec jekyll serve --open-url $argv
end
