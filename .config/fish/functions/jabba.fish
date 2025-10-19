#!/usr/bin/env fish
# https://github.com/shyiko/jabba
# https://raw.githubusercontent.com/shyiko/jabba/master/install.sh
function jabba \
        --description='Fish shell wrapper for jabba'
    set fd3 (mktemp /tmp/jabba-fd3.XXXXXX)

    # Run jabba and save output to temp file
    set -lx JABBA_SHELL_INTEGRATION ON
    # eval (brew_home jabba)/bin/jabba $argv 3> $fd3
    command jabba $argv 3> $fd3
    set exit_code $status

    # Convert output to fish
    eval (cat $fd3 | sed "s/^export/set -xg/g" | sed "s/^unset/set -e/g" | tr '=' ' ' | sed "s/:/\" \"/g" | tr '\\n' ';')

    # Cleanup
    rm -f $fd3
    return $exit_code
end
