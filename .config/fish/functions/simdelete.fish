function simdelete --description='Deletes old simulators'
    xcrun simctl delete unavailable
end
