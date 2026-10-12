# cron_list - Prints cron file
export def cron_list [] {
    ^crontab -l
}
