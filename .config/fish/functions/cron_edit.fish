#!/usr/bin/env fish
function cron_edit \
    --description='Opens cron file in an editor.'

    crontab -e
end
