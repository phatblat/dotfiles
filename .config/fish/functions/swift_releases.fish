function swift_releases \
        --description='Check for Swift releases' \
        --argument-names swift_version days

    set -l branch_name development

    if test -n "$swift_version"
        set swift_version "-$swift_version"
        set branch_name "swift$swift_version-branch"
    end

    if test -z "$days"
        set days 7
    end

    echo "Checking for Swift $branch_name snapshot releases ($days days)"
    echo

    set -l year (date "+%Y")
    set -l month (date "+%m")
    set -l current_day (date "+%d")

    for day in (jot - $current_day 1)
        # Zero pad month and day
        set month (printf "%02d" $month)
        set day (printf "%02d" $day)

        set -l date $year-$month-$day
        echo $date

        set -l release_slug "swift$swift_version-DEVELOPMENT-SNAPSHOT-$date-a"
        set -l url "https://swift.org/builds/$branch_name/xcode/$release_slug/$release_slug-osx.pkg"
        echo $url

        curl \
            --head \
            --location \
            --write-out "%{http_code}\n\n" \
            $url

        set days (math "$days - 1")
        if test $days -le 0
            return
        end
    end
end
