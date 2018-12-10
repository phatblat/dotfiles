function swift_releases --description='Check for Swift releases'
    set -l year (date "+%Y")
    set -l month (date "+%m")
    set -l current_day (date "+%d")

    for day in (jot - $current_day 1)
        # Zero pad month and day
        set month (printf "%02d" $month)
        set day (printf "%02d" $day)

        set -l date $year-$month-$day
        echo $date

        set -l release_slug "swift-DEVELOPMENT-SNAPSHOT-$date-a"
        set -l url "https://swift.org/builds/development/xcode/$release_slug/$release_slug-osx.pkg"
        echo $url

        curl \
            --head \
            --location \
            --write-out "%{http_code}\n\n" \
            $url
    end
end
