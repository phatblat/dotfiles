function served \
    --wraps=jekyll \
    --description 'Runs Jekyll server in the background.'

    bundle exec serve --incremental --detach $argv
end
