# Prints date in ISO-8601 format.
function date_iso8601 --argument-names format
    if test -z $format
        set format "timezone"
    end

    switch $format
        case s sh short
            # Short
            date "+%Y-%m-%d"
        case z gmt
            # GMT
            date -u +"%Y-%m-%dT%H:%M:%SZ"
        case '*' timezone
            # Time Zone
            date +%Y-%m-%dT%H:%M:%S%z
    end
end
