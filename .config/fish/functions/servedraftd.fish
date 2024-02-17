function servedraftd \
    --wraps=jekyll \
    --description='Runs Jekyll server in the background showing drafts.'

    servedraft --detach $argv
end
