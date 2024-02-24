function epoc_date \
    --description 'Converts epoc timestamps to a date' \
    --argument-names epoc_timestamp

    # macos format
    # date -r 1587570452

    # coreutils format
    date -d @$epoc_timestamp --rfc-3339=date
end
