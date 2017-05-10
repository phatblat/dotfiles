# Reload Cron file.
function cron_reload
    crontab ~/.dotfiles/cron/cron.file

    # Show the newly loaded job configuartion
    echo "Cron file reloaded:"
    cron_list
end
