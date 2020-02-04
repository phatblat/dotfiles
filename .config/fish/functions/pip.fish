# https://stackoverflow.com/questions/58451650/pip-no-longer-working-after-update-error-module-object-is-not-callable
function pip \
    --description='Wrapper for pip' \
    --wraps=pip

    python -m pip $argv
end

