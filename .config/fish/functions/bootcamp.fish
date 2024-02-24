function bootcamp \
    --description 'Restarts to Windows bootcamp'

    # https://apple.stackexchange.com/questions/9492/how-to-quickly-reboot-from-osx-to-windows-and-back
    /usr/sbin/bless -mount /Volumes/BOOTCAMP --setBoot --nextonly
    and restart
end
