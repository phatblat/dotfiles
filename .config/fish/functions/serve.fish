# Run Jekyll server in the foreground with the given environment variables.
function serve
    set reflog_content ~/dev/markdown/reflog/www
    pushd $reflog_content

    env (cat .env | xargs) bundle exec "jekyll serve $argv"
    popd
end
