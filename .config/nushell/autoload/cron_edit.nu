# cron_edit - Opens cron file in an editor
export def cron_edit [] {
    ^crontab -e
}
