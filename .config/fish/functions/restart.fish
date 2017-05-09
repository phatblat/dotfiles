# Restarts the computer without prompt
function restart
    if test (fdesetup isactive) = "true"
        # FileVault authenticated restart
        sudo fdesetup authrestart -verbose
    else
        # Normal restart
        sudo shutdown -r now "Rebooting now"
    end
end
