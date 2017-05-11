# Reload Cron file.
function cron_reload
    crontab ~/.dotfiles/cron/cron.file

    if not status is-interactive
        return 0
    end

    # Show the newly loaded job configuartion
    echo "Cron file reloaded:"
    cron_list
end
