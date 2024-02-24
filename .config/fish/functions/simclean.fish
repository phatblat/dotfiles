function simclean \
    --description 'Deletes all unavailable simulators'

    xcrun simctl delete unavailable
end
