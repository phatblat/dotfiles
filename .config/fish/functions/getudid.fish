function getudid \
    --description='Prints and copies the UDID of the connected iOS device.'

    set -l udid (system_profiler SPUSBDataType \
        | grep -A 11 -w "iPad\|iPhone\|iPad" \
        | grep "Serial Number" \
        | awk '{ print $3 }')

    if test -z $udid
        echo "No device detected. Please ensure an iOS device is plugged in."
        exit 1
    else
        for identifier in $udid
            echo -n $identifier | pbcopy
            echo "UDID: $identifier"
        end
    end
end
