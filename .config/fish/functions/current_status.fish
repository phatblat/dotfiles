# Debugging for the status function.
#
# User:
# - is-login
# - is-interactive
# - is-block
# - is-interactive-job-control
#
# Cron:
# - is-block
# - is-interactive-job-control
function current_status
    set -l flags is-login is-interactive is-block is-command-substitution is-no-job-control is-full-job-control is-interactive-job-control

    for flag in $flags
        status $flag; and echo $flag
    end
end
