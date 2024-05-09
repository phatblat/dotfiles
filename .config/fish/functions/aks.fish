function aks \
    --description 'Restarts adb server'
    adb kill-server && adb start-server && adb devices -l
end
