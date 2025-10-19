#!/usr/bin/env fish
function servedraft \
        --wraps=jekyll \
        --description='Runs Jekyll server showing drafts.'

    bundle exec serve --draft $argv
end
