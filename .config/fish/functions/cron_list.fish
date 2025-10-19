#!/usr/bin/env fish
function cron_list \
    --description='Prints cron file.'

    crontab -l
end
