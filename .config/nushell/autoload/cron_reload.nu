# cron_reload - Reloads cron file
export def cron_reload [] {
    let cron_file = ($env.HOME + "/.dotfiles/cron/cron.file")
    ^crontab $cron_file
    print "Cron file reloaded:"
    cron_list
}
