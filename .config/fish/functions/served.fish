# Run Jekyll server in the background.
function served --wraps serve
    serve --detach $argv
end
