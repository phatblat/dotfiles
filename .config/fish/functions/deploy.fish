function deploy \
    --description='Builds and deploys static content.'

    set reflog_content ~/dev/www/reflog/www
    if test "$pwd" != "$reflog_content"
        pushd $reflog_content
    end

    ../bin/jekyll build
    ../bin/octopress deploy
end
