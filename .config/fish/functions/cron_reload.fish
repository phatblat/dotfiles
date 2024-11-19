function cron_reload \
    --description='Reloads cron file.'

    crontab $HOME/.dotfiles/cron/cron.file

    if not status is-interactive
        return 0
    end

    # Show the newly loaded job configuartion
    echo "Cron file reloaded:"
    cron_list
end
