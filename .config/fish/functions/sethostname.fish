# http://osxdaily.com/2012/10/24/set-the-hostname-computer-name-and-bonjour-name-separately-in-os-x/
# https://www.naschenweng.info/2016/12/29/os-set-hostname-computer-name-bonjour-command-line/
function sethostname \
    --description 'Sets system hostname in all the various places' \
    --argument-names new_name

    if test -z "$new_name"
        error "Usage: sethostname new_name"
        return 1
    end

    if not user_is_admin
        error "You must be an admion to run this command."
        return 1
    end

    sudo scutil --set ComputerName "$new_name"
    sudo scutil --set HostName "$new_name"
    sudo scutil --set LocalHostName "$new_name"
    sudo defaults write \
        /Library/Preferences/SystemConfiguration/com.apple.smb.server \
        NetBIOSName \
        -string "$new_name"
end
