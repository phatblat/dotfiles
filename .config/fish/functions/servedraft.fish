function servedraft
        --wraps jekyll \
        --description='Runs Jekyll server showing drafts.'
    serve --draft $argv
end
