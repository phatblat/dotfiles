#!/usr/bin/env fish
# https://stackoverflow.com/questions/58451650/pip-no-longer-working-after-update-error-module-object-is-not-callable
function pip \
    --description='Wrapper for pip' \
    --wraps=pip

    CFLAGS=-I(brew --prefix)/include \
    LDFLAGS=-L(brew --prefix)/lib \
    command pip $argv
end
