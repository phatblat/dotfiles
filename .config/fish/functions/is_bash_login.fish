#!/usr/bin/env fish
function is_bash_login \
    --description "Tests whether the parent login shell is bash"

    string match --quiet --regex '.*bash$' $SHELL
end
