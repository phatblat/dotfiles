#!/usr/bin/env fish
function swift_releases \
        --description='Check for Swift releases' \
        --argument-names swift_version days

    set -l branch_name development

    if test "$swift_version" = "trunk"
        # use default branch name
        # clear swift version
        set -e swift_version
    else if test -n "$swift_version"
        set swift_version "-$swift_version"
        set branch_name "swift$swift_version-branch"
    end

    if test -z "$days"
        # Default to a week
        set days 7
    end

    echo "Checking for Swift $branch_name snapshot releases ($days days)"
    echo

    set -l year (date "+%Y")
    set -l months (date "+%m")
    set -l current_day (date "+%e") # (1-31); single digits are preceded by a blank.

    # Detect month wrap around
    if test $days -gt $current_day
        # Add previous month
        set -l prev_month
        if test $months = 1
            set prev_month 12
        else
            set prev_month (math -- $months - 1)
        end

        set months $months $prev_month
    end

    # This is typically a single iteration unless more days were requested than
    # have passed in the current month.
    for month in $months
        # Start on the last day of the month in the 2nd iteration
        set -l days_in_month 31
        switch $month
            case 4 6 9 11
                set days_in_month 30
            case 2
                set days_in_month 28
        end
        if test $current_day -gt $days_in_month
            set current_day $days_in_month
        end

        # jot generates a decending sequence of integers
        for day in (jot $days $current_day 1 -1)
            # Zero pad month and day
            if test (string length $month) -eq 1
                set month (printf "%02d" $month)
            end
            if test (string length $day) -eq 1
                set day (printf "%02d" $day)
            end

            set -l date $year-$month-$day
            echo -n $date

            set -l release_slug "swift$swift_version-DEVELOPMENT-SNAPSHOT-$date-a"
            set -l url "https://swift.org/builds/$branch_name/xcode/$release_slug/$release_slug-osx.pkg"

            set -l status_code (
                curl \
                    --head \
                    --location \
                    --silent \
                    --output /dev/null \
                    --write-out "%{http_code}" \
                    $url
            )

            echo " - $status_code"
            if test $status_code -eq 200
                echo $url
            end

            # Decrement days count for previous month
            set days (math -- $days - 1)
        end

        # Start at the end of the previous month
        set current_day 31
    end
end
