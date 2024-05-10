function adevices \
    --description 'List adb emulators and connected devices.'
    adb devices -l $argv
end
