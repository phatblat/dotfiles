# Restarts the computer without prompt
function restart
    if not user_is_admin
        echo "You must be an admin to run this command."
        return 1
    end

    if test (fdesetup isactive) = "true"
        # FileVault authenticated restart
        sudo fdesetup authrestart -verbose
    else
        # Normal restart
        sudo shutdown -r now "Rebooting now"
    end
end
