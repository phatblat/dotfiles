#!/usr/bin/env fish
# Indicates whether a user is present
function user_present
    if begin status is-login
            and status is-interactive
            and status is-interactive-job-control
            # and not status is-command-substitution
            # and not status is-block
        end
        return 0
    else
        return 1
    end
end
