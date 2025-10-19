#!/usr/bin/env fish
function ane \
    --description='Git amend, without changing the commit message.'

    amend --no-edit
end
