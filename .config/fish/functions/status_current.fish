#!/usr/bin/env fish
# Debugging for the status function.
#
# User:
# - is-login
# - is-interactive
# - is-block
# - is-interactive-job-control
#
# su user (admin)
# - is-interactive
# - is-block
# - is-full-job-control
#
# Cron:
# - is-block
# - is-interactive-job-control
function status_current
    set -l flags is-login is-interactive is-block is-command-substitution is-no-job-control is-full-job-control is-interactive-job-control

    for flag in $flags
        status $flag; and echo $flag
    end
end
