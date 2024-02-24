# https://github.com/ogham/dog
function dig \
    --description 'Redirects to dog' \
    --wraps dig

    dog $argv
end
