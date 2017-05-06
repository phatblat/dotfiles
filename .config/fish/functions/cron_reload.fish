# 
function cron_reload
    crontab $HOME/.dotfiles/cron/cron.file $argv
end

