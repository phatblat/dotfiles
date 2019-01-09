function deploy \
    --description='Builds and deploys static content.'

    set reflog_content ~/dev/www/reflog
    if test "$pwd" != "$reflog_content"
        pushd $reflog_content
    end

    jekyll build
    octopress deploy
end
